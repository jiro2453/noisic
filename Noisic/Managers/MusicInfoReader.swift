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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.requestAuthorization()
        }
    }

    private func requestAuthorization() {
        #if targetEnvironment(simulator)
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
            break
        }
        #endif
    }

    private func setupPlayer() {
        guard !isSetup else { return }
        isSetup = true

        player = MPMusicPlayerController.systemMusicPlayer
        player?.beginGeneratingPlaybackNotifications()
        player?.repeatMode = .all
        isAuthorized = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player
        )

        updateMusicInfo()

        // 1秒ごとに更新
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMusicInfo()
        }
    }

    @objc private func handleNotification() {
        updateMusicInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.endGeneratingPlaybackNotifications()
        timer?.invalidate()
    }

    private func updateMusicInfo() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateMusicInfo()
            }
            return
        }

        guard let player = player, let nowPlaying = player.nowPlayingItem else {
            musicInfo = MusicInfo(title: nil, artist: nil, artwork: nil, isPlaying: false)
            isPlaying = false
            currentTime = 0
            duration = 0
            return
        }

        let title = nowPlaying.title
        let artist = nowPlaying.artist

        // アートワークを取得
        var artwork: UIImage? = nil

        // 方法1: 曲から直接取得
        if let mpArtwork = nowPlaying.artwork {
            artwork = mpArtwork.image(at: CGSize(width: 300, height: 300))
        }

        // 方法2: アルバムから取得
        if artwork == nil {
            let albumId = nowPlaying.albumPersistentID
            let query = MPMediaQuery.albums()
            query.addFilterPredicate(MPMediaPropertyPredicate(
                value: albumId,
                forProperty: MPMediaItemPropertyAlbumPersistentID
            ))
            if let collection = query.collections?.first,
               let repItem = collection.representativeItem,
               let repArtwork = repItem.artwork {
                artwork = repArtwork.image(at: CGSize(width: 300, height: 300))
            }
        }

        let playing = player.playbackState == .playing

        musicInfo = MusicInfo(title: title, artist: artist, artwork: artwork, isPlaying: playing)
        isPlaying = playing
        currentTime = player.currentPlaybackTime
        duration = nowPlaying.playbackDuration
    }

    // MARK: - Playback Controls

    func playPause() {
        guard let player = player else { return }
        if player.playbackState == .playing {
            player.pause()
        } else if player.nowPlayingItem != nil {
            player.play()
        }
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

        if let currentIndex = albums.firstIndex(where: { $0.id == currentAlbumId }) {
            let nextIndex = (currentIndex + 1) % albums.count
            libraryManager.playAlbum(albums[nextIndex])
        } else if let firstAlbum = albums.first {
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
