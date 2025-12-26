//
//  VideoPlayerView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoName: String
    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            if let player = player {
                ZStack {
                    Color.black

                    VideoPlayer(player: player)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .disabled(true)
                        .blur(radius: 5)
                }
            } else {
                Color.black
            }
        }
        .onAppear {
            if player == nil {
                setupPlayer()
            }
            player?.play()
        }
        .onDisappear {
            player?.pause()
        }
        .ignoresSafeArea()
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = true
        newPlayer.automaticallyWaitsToMinimizeStalling = false

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
