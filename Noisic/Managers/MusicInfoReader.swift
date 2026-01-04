//
//  MusicInfoReader.swift
//  Noisic
//
//  Created on 2025-12-21
//

import MediaPlayer
import Combine

class MusicInfoReader: ObservableObject {
    @Published var musicInfo = MusicInfo(title: nil, artist: nil, artwork: nil, isPlaying: false)
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isAuthorized: Bool = false

    private var timer: Timer?
    private var player: MPMusicPlayerController?
    private var isSetup = false
    weak var libraryManager: LibraryManager?

    // アートワークのキャッシュ
    private var cachedArtwork: UIImage?
    private var cachedArtworkId: UInt64 = 0
    private var artworkRetryCount = 0
    private let maxArtworkRetries = 20

    // 最後に成功したアートワーク（同じ曲のリトライ用）
    private var lastSuccessfulArtwork: UIImage?
    private var lastSuccessfulArtworkId: UInt64 = 0

    init() {
        // Delay initialization to avoid blocking app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.requestAuthorization()
        }
    }

    private func requestAuthorization() {
        #if targetEnvironment(simulator)
        // MPMusicPlayerController doesn't work on simulator
        return
        #else
        let status = MPMediaLibrary.authorizationStatus()

        switch status {
        case .authorized:
            setupPlayer()
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self?.setupPlayer()
                    }
                }
            }
        default:
            // Denied or restricted
            break
        }
        #endif
    }

    private func setupPlayer() {
        guard !isSetup else { return }
        isSetup = true

        player = MPMusicPlayerController.systemMusicPlayer
        player?.beginGeneratingPlaybackNotifications()
        // アルバム内で自動ループ
        player?.repeatMode = .all
        isAuthorized = true

        // ライブラリ変更の通知を開始
        MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()

        // 曲が変わった時の通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemDidChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )

        // 再生状態が変わった時の通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateDidChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player
        )

        // ライブラリ変更の通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(libraryDidChange),
            name: .MPMediaLibraryDidChange,
            object: nil
        )

        // プレイヤーの状態を準備
        player?.prepareToPlay()

        startMonitoring()
    }

    @objc private func nowPlayingItemDidChange() {
        // 曲が変わったらキャッシュをリセットして即座に更新
        cachedArtwork = nil
        cachedArtworkId = 0
        artworkRetryCount = 0
        // 少し遅延させてから更新（アートワークの準備を待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateMusicInfo()
        }
    }

    @objc private func playbackStateDidChange() {
        updateMusicInfo()
    }

    @objc private func libraryDidChange() {
        // ライブラリが変更されたらキャッシュをクリア
        cachedArtwork = nil
        cachedArtworkId = 0
        updateMusicInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        MPMediaLibrary.default().endGeneratingLibraryChangeNotifications()
        player?.endGeneratingPlaybackNotifications()
        stopMonitoring()
    }

    private func startMonitoring() {
        // Update immediately
        updateMusicInfo()

        // Poll for updates every 0.5 second
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMusicInfo()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMusicInfo() {
        // 必ずメインスレッドで実行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.updateMusicInfo()
            }
            return
        }

        guard let player = player, let nowPlaying = player.nowPlayingItem else {
            self.musicInfo = MusicInfo(title: nil, artist: nil, artwork: nil, isPlaying: false)
            self.isPlaying = false
            self.currentTime = 0
            self.duration = 0
            return
        }

        let title = nowPlaying.title
        let artist = nowPlaying.artist
        let itemId = nowPlaying.persistentID

        // 曲が変わった場合はキャッシュをリセット
        if itemId != cachedArtworkId {
            cachedArtworkId = itemId
            cachedArtwork = nil
            artworkRetryCount = 0
        }

        let playing = player.playbackState == .playing
        let time = player.currentPlaybackTime
        let trackDuration = nowPlaying.playbackDuration

        // キャッシュがあればそれを使用
        if let cached = cachedArtwork {
            self.musicInfo = MusicInfo(title: title, artist: artist, artwork: cached, isPlaying: playing)
            self.isPlaying = playing
            self.currentTime = time
            self.duration = trackDuration
            return
        }

        // アートワークを同期的に取得（メインスレッド上）
        let artwork = fetchArtwork(for: nowPlaying)

        if let artwork = artwork {
            cachedArtwork = artwork
            lastSuccessfulArtwork = artwork
            lastSuccessfulArtworkId = itemId
            self.musicInfo = MusicInfo(title: title, artist: artist, artwork: artwork, isPlaying: playing)
        } else {
            // アートワークが取得できなかった場合
            // 同じ曲のリトライ中のみ前回のアートワークを使用（違う曲の場合はnil）
            let fallbackArtwork = (lastSuccessfulArtworkId == itemId) ? lastSuccessfulArtwork : nil
            self.musicInfo = MusicInfo(title: title, artist: artist, artwork: fallbackArtwork, isPlaying: playing)

            if artworkRetryCount < maxArtworkRetries {
                artworkRetryCount += 1
                scheduleArtworkRetry()
            }
        }

        self.isPlaying = playing
        self.currentTime = time
        self.duration = trackDuration
    }

    /// メインスレッドでアートワークを取得
    private func fetchArtwork(for item: MPMediaItem) -> UIImage? {
        // 方法0: プレイヤーの現在のnowPlayingItemから直接取得（最新状態）
        if let currentItem = player?.nowPlayingItem,
           currentItem.persistentID == item.persistentID,
           let currentArtwork = currentItem.artwork {
            let sizes = [
                CGSize(width: 600, height: 600),
                CGSize(width: 400, height: 400),
                CGSize(width: 300, height: 300)
            ]
            for size in sizes {
                if let image = currentArtwork.image(at: size) {
                    return image
                }
            }
        }

        // 方法1: MPMediaItemから直接取得
        if let artworkCatalog = item.artwork {
            let sizes = [
                CGSize(width: 600, height: 600),
                CGSize(width: 400, height: 400),
                CGSize(width: 300, height: 300),
                CGSize(width: 200, height: 200),
                CGSize(width: 100, height: 100)
            ]

            for size in sizes {
                if let image = artworkCatalog.image(at: size) {
                    return image
                }
            }

            // Fallback to bounds size
            let boundsSize = artworkCatalog.bounds.size
            if boundsSize.width > 0 && boundsSize.height > 0 {
                if let image = artworkCatalog.image(at: boundsSize) {
                    return image
                }
            }
        }

        // 方法2: アルバムクエリから取得
        let albumId = item.albumPersistentID
        let query = MPMediaQuery.albums()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: albumId,
            forProperty: MPMediaItemPropertyAlbumPersistentID
        ))

        if let collection = query.collections?.first {
            // 代表曲から取得
            if let repItem = collection.representativeItem,
               let repArtwork = repItem.artwork {
                let sizes = [CGSize(width: 400, height: 400), CGSize(width: 300, height: 300), CGSize(width: 200, height: 200)]
                for size in sizes {
                    if let image = repArtwork.image(at: size) {
                        return image
                    }
                }
            }

            // アルバム内の全曲をチェック
            for trackItem in collection.items {
                if let trackArtwork = trackItem.artwork {
                    let sizes = [CGSize(width: 300, height: 300), CGSize(width: 200, height: 200)]
                    for size in sizes {
                        if let image = trackArtwork.image(at: size) {
                            return image
                        }
                    }
                }
            }
        }

        // 方法3: LibraryManagerから取得
        if let libraryManager = libraryManager,
           let album = libraryManager.combinedAlbums.first(where: { $0.id == albumId }),
           let albumArtwork = album.artwork {
            return albumArtwork
        }

        // 方法4: 全曲クエリから取得
        let songsQuery = MPMediaQuery.songs()
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(
            value: item.persistentID,
            forProperty: MPMediaItemPropertyPersistentID
        ))

        if let foundItem = songsQuery.items?.first,
           let foundArtwork = foundItem.artwork {
            let sizes = [CGSize(width: 300, height: 300), CGSize(width: 200, height: 200)]
            for size in sizes {
                if let image = foundArtwork.image(at: size) {
                    return image
                }
            }
        }

        return nil
    }

    private func scheduleArtworkRetry() {
        // リトライ回数に応じて待機時間を増やす（0.5秒、1秒、1.5秒...最大3秒）
        let delay = min(0.5 * Double(artworkRetryCount), 3.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.updateMusicInfo()
        }
    }

    // MARK: - Playback Controls

    func playPause() {
        guard let player = player else { return }
        if player.playbackState == .playing {
            player.pause()
        } else {
            // If there's a current item, play it
            if player.nowPlayingItem != nil {
                player.play()
            }
        }
        // Update immediately after action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateMusicInfo()
        }
    }

    func skipToNext() {
        guard let player = player, let nowPlaying = player.nowPlayingItem else {
            player?.skipToNextItem()
            return
        }

        let trackNumber = nowPlaying.albumTrackNumber
        let trackCount = nowPlaying.albumTrackCount

        // 最後の曲または1曲のみの場合は次のアルバムを再生
        if trackCount <= 1 || trackNumber >= trackCount {
            playNextAlbum()
        } else {
            player.skipToNextItem()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateMusicInfo()
        }
    }

    private func playNextAlbum() {
        guard let libraryManager = libraryManager,
              let player = player,
              let currentItem = player.nowPlayingItem else { return }

        let currentAlbumId = currentItem.albumPersistentID
        let albums = libraryManager.combinedAlbums

        // 現在のアルバムのインデックスを見つける
        if let currentIndex = albums.firstIndex(where: { $0.id == currentAlbumId }) {
            // 次のアルバムを取得（ループ）
            let nextIndex = (currentIndex + 1) % albums.count
            let nextAlbum = albums[nextIndex]
            libraryManager.playAlbum(nextAlbum)
        } else if let firstAlbum = albums.first {
            // 見つからない場合は最初のアルバムを再生
            libraryManager.playAlbum(firstAlbum)
        }
    }

    func skipToPrevious() {
        player?.skipToPreviousItem()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateMusicInfo()
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentPlaybackTime = time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateMusicInfo()
        }
    }
}
