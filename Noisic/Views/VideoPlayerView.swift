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
    @State private var observer: NSObjectProtocol?

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
            cleanupPlayer()
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

        // Loop the video
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }

        player = newPlayer
        newPlayer.play()
    }

    private func cleanupPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }

        observer = nil
        player = nil
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
