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
    private let maxArtworkRetries = 5

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
        startMonitoring()
    }

    deinit {
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

        // 曲が変わった場合はキャッシュをリセット
        if itemId != cachedArtworkId {
            cachedArtworkId = itemId
            cachedArtwork = nil
            artworkRetryCount = 0
        }

        // アートワークを取得（キャッシュがあればそれを使用）
        let artwork: UIImage? = {
            // 既にキャッシュがあればそれを使う
            if let cached = cachedArtwork {
                return cached
            }

            guard let artworkCatalog = nowPlaying.artwork else {
                // リトライカウントを増やしてあとで再試行
                if artworkRetryCount < maxArtworkRetries {
                    artworkRetryCount += 1
                    scheduleArtworkRetry()
                }
                return nil
            }

            // Try different sizes in order of preference
            let sizes = [
                CGSize(width: 600, height: 600),
                CGSize(width: 300, height: 300),
                CGSize(width: 200, height: 200),
                CGSize(width: 100, height: 100)
            ]

            for size in sizes {
                if let image = artworkCatalog.image(at: size) {
                    cachedArtwork = image
                    return image
                }
            }

            // Fallback to bounds size
            let boundsSize = artworkCatalog.bounds.size
            if boundsSize.width > 0 && boundsSize.height > 0 {
                if let image = artworkCatalog.image(at: boundsSize) {
                    cachedArtwork = image
                    return image
                }
            }

            // アートワークが取得できなかった場合はリトライ
            if artworkRetryCount < maxArtworkRetries {
                artworkRetryCount += 1
                scheduleArtworkRetry()
            }

            return nil
        }()

        let playing = player.playbackState == .playing
        let time = player.currentPlaybackTime
        let trackDuration = nowPlaying.playbackDuration

        DispatchQueue.main.async {
            self.musicInfo = MusicInfo(title: title, artist: artist, artwork: artwork, isPlaying: playing)
            self.isPlaying = playing
            self.currentTime = time
            self.duration = trackDuration
        }
    }

    private func scheduleArtworkRetry() {
        // 0.3秒後にリトライ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
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
