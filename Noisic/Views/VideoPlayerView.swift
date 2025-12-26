//
//  VideoPlayerView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoName: String
    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .blur(radius: 15)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                Color.black
            }
        }
        .onAppear {
            setupPlayer()
        }
        .ignoresSafeArea()
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("Video file not found: \(videoName).mp4")
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = true // Video is muted, only ambient audio plays

        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }

        player = newPlayer
    }
}
