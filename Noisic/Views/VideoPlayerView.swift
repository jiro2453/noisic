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
        Group {
            if let player = player {
                VideoPlayerLayerView(player: player)
                    .blur(radius: 5)
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
            print("❌ Video file not found: \(videoName).mp4")
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
        print("✅ Video player setup complete: \(videoName).mp4")
    }
}

// Custom video player without controls
struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill

        view.layer.addSublayer(playerLayer)
        context.coordinator.playerLayer = playerLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let playerLayer = context.coordinator.playerLayer {
                playerLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}
