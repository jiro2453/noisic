//
//  MusicInfoReader.swift
//  Noisic
//
//  Created on 2025-12-21
//

import MediaPlayer
import Combine

class MusicInfoReader: ObservableObject {
    @Published var musicInfo = MusicInfo(title: nil, artist: nil, artwork: nil)

    private var timer: Timer?

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        // Update immediately
        updateMusicInfo()

        // Poll for updates every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMusicInfo()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMusicInfo() {
        let player = MPMusicPlayerController.systemMusicPlayer

        guard let nowPlaying = player.nowPlayingItem else {
            DispatchQueue.main.async {
                self.musicInfo = MusicInfo(title: nil, artist: nil, artwork: nil)
            }
            return
        }

        let title = nowPlaying.title
        let artist = nowPlaying.artist
        let artwork = nowPlaying.artwork?.image(at: CGSize(width: 300, height: 300))

        DispatchQueue.main.async {
            self.musicInfo = MusicInfo(title: title, artist: artist, artwork: artwork)
        }
    }
}
