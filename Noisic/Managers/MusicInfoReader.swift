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
        updateMusicInfo()
    }

    @objc private func playbackStateDidChange() {
        updateMusicInfo()
    }

    @objc private func libraryDidChange() {
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

        // シンプルに取得（曲名・アーティスト名と同様）
        let title = nowPlaying.title
        let artist = nowPlaying.artist

        // アートワークを取得
        var artwork: UIImage? = nil

        // デバッグ: アートワークの状態を確認
        let hasArtworkProperty = nowPlaying.artwork != nil
        let artworkBounds = nowPlaying.artwork?.bounds ?? .zero
        print("🎵 Title: \(title ?? "nil"), Artist: \(artist ?? "nil")")
        print("🖼️ hasArtwork: \(hasArtworkProperty), bounds: \(artworkBounds)")

        // 方法1: 直接プロパティから取得
        if let directArtwork = nowPlaying.artwork {
            // 複数のサイズを試す
            let sizes: [CGSize] = [
                artworkBounds.size,
                CGSize(width: 600, height: 600),
                CGSize(width: 300, height: 300),
                CGSize(width: 200, height: 200),
                CGSize(width: 100, height: 100),
                CGSize(width: 50, height: 50)
            ]
            for size in sizes {
                if size.width > 0, let img = directArtwork.image(at: size) {
                    artwork = img
                    print("✅ Artwork loaded at size: \(size)")
                    break
                }
            }
            if artwork == nil {
                print("❌ Failed to get image from artwork at any size")
            }
        } else {
            print("❌ nowPlaying.artwork is nil")
        }

        // 方法2: persistentIDで新しくクエリして取得
        if artwork == nil {
            let query = MPMediaQuery.songs()
            query.addFilterPredicate(MPMediaPropertyPredicate(
                value: nowPlaying.persistentID,
                forProperty: MPMediaItemPropertyPersistentID
            ))
            if let freshItem = query.items?.first {
                print("🔍 Query found item: \(freshItem.title ?? "nil")")
                if let freshArtwork = freshItem.artwork {
                    print("🔍 Query item has artwork, bounds: \(freshArtwork.bounds)")
                    if let img = freshArtwork.image(at: CGSize(width: 300, height: 300)) {
                        artwork = img
                        print("✅ Artwork loaded from query")
                    }
                } else {
                    print("❌ Query item artwork is nil")
                }
            } else {
                print("❌ Query returned no items")
            }
        }

        let playing = player.playbackState == .playing
        let time = player.currentPlaybackTime
        let trackDuration = nowPlaying.playbackDuration

        self.musicInfo = MusicInfo(title: title, artist: artist, artwork: artwork, isPlaying: playing)
        self.isPlaying = playing
        self.currentTime = time
        self.duration = trackDuration
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
