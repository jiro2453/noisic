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

    private var lastLoggedItemId: UInt64 = 0

    @objc private func nowPlayingItemDidChange() {
        // 曲が変わった時だけログを出力
        if let item = player?.nowPlayingItem, item.persistentID != lastLoggedItemId {
            lastLoggedItemId = item.persistentID
            let hasArtwork = item.artwork != nil
            print("🎵 Now Playing: \(item.title ?? "nil") - hasArtwork: \(hasArtwork)")
        }
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
        let artwork = nowPlaying.artwork?.image(at: CGSize(width: 300, height: 300))

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
