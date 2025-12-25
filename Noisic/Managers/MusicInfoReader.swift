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

    private var timer: Timer?
    private let player = MPMusicPlayerController.systemMusicPlayer

    init() {
        print("=== MusicInfoReader initializing ===")
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        // Update immediately
        updateMusicInfo()

        // Poll for updates every 0.5 seconds for smoother playback tracking
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMusicInfo()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMusicInfo() {
        guard let nowPlaying = player.nowPlayingItem else {
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
        let artwork = nowPlaying.artwork?.image(at: CGSize(width: 300, height: 300))
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

    // MARK: - Playback Controls

    func playPause() {
        if player.playbackState == .playing {
            player.pause()
        } else {
            player.play()
        }
        updateMusicInfo()
    }

    func skipToNext() {
        player.skipToNextItem()
        updateMusicInfo()
    }

    func skipToPrevious() {
        player.skipToPreviousItem()
        updateMusicInfo()
    }

    func seek(to time: TimeInterval) {
        player.currentPlaybackTime = time
        updateMusicInfo()
    }
}
