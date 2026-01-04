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

    // 最後に成功したアートワーク（フォールバック用）
    private var lastSuccessfulArtwork: UIImage?
    private var isLoadingArtwork = false

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

        // 曲が変わった時の通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemDidChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )

        startMonitoring()
    }

    @objc private func nowPlayingItemDidChange() {
        // 曲が変わったらキャッシュをリセットして即座に更新
        cachedArtwork = nil
        cachedArtworkId = 0
        artworkRetryCount = 0
        updateMusicInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.endGeneratingPlaybackNotifications()
        stopMonitoring()
    }

    private func startMonitoring() {
        // Update immediately
        updateMusicInfo()

        // Poll for updates every 1 second (reduced from 0.5 for better performance)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMusicInfo()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMusicInfo() {
        guard let player = player, let nowPlaying = player.nowPlayingItem else {
            DispatchQueue.main.async {
                self.musicInfo = MusicInfo(title: nil, artist: nil, artwork: nil, isPlaying: false)
                self.isPlaying = false
                self.currentTime = 0
                self.duration = 0
            }
            return
        }

        let title = nowPlaying.title
        let artist = nowPlaying.artist
        let itemId = nowPlaying.persistentID
        let albumId = nowPlaying.albumPersistentID

        // 曲が変わった場合はキャッシュをリセット
        if itemId != cachedArtworkId {
            cachedArtworkId = itemId
            cachedArtwork = nil
            artworkRetryCount = 0
            isLoadingArtwork = false
        }

        let playing = player.playbackState == .playing
        let time = player.currentPlaybackTime
        let trackDuration = nowPlaying.playbackDuration

        // まずキャッシュがあればそれを使用
        if let cached = cachedArtwork {
            DispatchQueue.main.async {
                self.musicInfo = MusicInfo(title: title, artist: artist, artwork: cached, isPlaying: playing)
                self.isPlaying = playing
                self.currentTime = time
                self.duration = trackDuration
            }
            return
        }

        // アートワークをバックグラウンドで取得
        if !isLoadingArtwork {
            isLoadingArtwork = true
            loadArtworkAsync(for: nowPlaying, albumId: albumId, title: title, artist: artist)
        }

        // 一時的に最後のアートワークか nil を使用
        let tempArtwork = lastSuccessfulArtwork
        DispatchQueue.main.async {
            self.musicInfo = MusicInfo(title: title, artist: artist, artwork: tempArtwork, isPlaying: playing)
            self.isPlaying = playing
            self.currentTime = time
            self.duration = trackDuration
        }
    }

    private func loadArtworkAsync(for item: MPMediaItem, albumId: UInt64, title: String?, artist: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var artwork: UIImage?

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
                        artwork = image
                        break
                    }
                }

                // Fallback to bounds size
                if artwork == nil {
                    let boundsSize = artworkCatalog.bounds.size
                    if boundsSize.width > 0 && boundsSize.height > 0 {
                        artwork = artworkCatalog.image(at: boundsSize)
                    }
                }
            }

            // 方法2: アルバムのrepresentativeItemから取得
            if artwork == nil {
                let query = MPMediaQuery.albums()
                query.addFilterPredicate(MPMediaPropertyPredicate(
                    value: albumId,
                    forProperty: MPMediaItemPropertyAlbumPersistentID
                ))
                if let collection = query.collections?.first,
                   let repItem = collection.representativeItem,
                   let repArtwork = repItem.artwork {
                    let sizes = [CGSize(width: 400, height: 400), CGSize(width: 300, height: 300), CGSize(width: 200, height: 200)]
                    for size in sizes {
                        if let image = repArtwork.image(at: size) {
                            artwork = image
                            break
                        }
                    }
                }
            }

            // 方法3: アルバム内の全曲をチェック
            if artwork == nil {
                let query = MPMediaQuery.albums()
                query.addFilterPredicate(MPMediaPropertyPredicate(
                    value: albumId,
                    forProperty: MPMediaItemPropertyAlbumPersistentID
                ))
                if let collection = query.collections?.first {
                    for trackItem in collection.items {
                        if let trackArtwork = trackItem.artwork {
                            let sizes = [CGSize(width: 300, height: 300), CGSize(width: 200, height: 200)]
                            for size in sizes {
                                if let image = trackArtwork.image(at: size) {
                                    artwork = image
                                    break
                                }
                            }
                            if artwork != nil { break }
                        }
                    }
                }
            }

            // 方法4: LibraryManagerから取得
            if artwork == nil {
                DispatchQueue.main.sync {
                    if let libraryManager = self.libraryManager,
                       let album = libraryManager.combinedAlbums.first(where: { $0.id == albumId }),
                       let albumArtwork = album.artwork {
                        artwork = albumArtwork
                    }
                }
            }

            DispatchQueue.main.async {
                if let artwork = artwork {
                    self.cachedArtwork = artwork
                    self.lastSuccessfulArtwork = artwork
                    self.isLoadingArtwork = false

                    // 現在再生中の曲と一致する場合のみ更新
                    if let currentItem = self.player?.nowPlayingItem,
                       currentItem.persistentID == item.persistentID {
                        let playing = self.player?.playbackState == .playing ?? false
                        let time = self.player?.currentPlaybackTime ?? 0
                        let duration = currentItem.playbackDuration
                        self.musicInfo = MusicInfo(title: title, artist: artist, artwork: artwork, isPlaying: playing)
                        self.isPlaying = playing
                        self.currentTime = time
                        self.duration = duration
                    }
                } else {
                    // アートワークが見つからなかった場合はリトライ
                    self.isLoadingArtwork = false
                    if self.artworkRetryCount < self.maxArtworkRetries {
                        self.artworkRetryCount += 1
                        self.scheduleArtworkRetry()
                    }
                }
            }
        }
    }

    private func scheduleArtworkRetry() {
        // リトライ回数に応じて待機時間を増やす（0.3秒、0.6秒、0.9秒...最大3秒）
        let delay = min(0.3 * Double(artworkRetryCount), 3.0)
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
