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

    var body: some View {
        VideoPlayerContainer(videoName: videoName)
            .blur(radius: 5)
            .ignoresSafeArea()
    }
}

// UIViewControllerRepresentableを使用（UIViewRepresentableより安定）
struct VideoPlayerContainer: UIViewControllerRepresentable {
    let videoName: String

    func makeUIViewController(context: Context) -> VideoPlayerViewController {
        return VideoPlayerViewController(videoName: videoName)
    }

    func updateUIViewController(_ uiViewController: VideoPlayerViewController, context: Context) {
        // 動画名が変わった場合は再読み込み
        if uiViewController.currentVideoName != videoName {
            uiViewController.loadVideo(named: videoName)
        }
    }
}

class VideoPlayerViewController: UIViewController {
    var currentVideoName: String
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loopObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?

    init(videoName: String) {
        self.currentVideoName = videoName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // フォアグラウンドに戻ったときに再生を再開
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.player?.play()
        }

        // バックグラウンドスレッドで動画を読み込む
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadVideoAsync()
        }
    }

    private func loadVideoAsync() {
        guard let url = Bundle.main.url(forResource: currentVideoName, withExtension: "mp4") else {
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.player = newPlayer

            let layer = AVPlayerLayer(player: newPlayer)
            layer.videoGravity = .resizeAspectFill
            layer.frame = self.view.bounds
            self.view.layer.addSublayer(layer)
            self.playerLayer = layer

            // ループ再生
            self.loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }

            newPlayer.play()
        }
    }

    func loadVideo(named name: String) {
        currentVideoName = name
        cleanupPlayer()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadVideoAsync()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    private func cleanupPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()

        if let loopObserver = loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }

        loopObserver = nil
        player = nil
        playerLayer = nil
    }

    private func cleanup() {
        cleanupPlayer()

        if let foregroundObserver = foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
        foregroundObserver = nil
    }

    deinit {
        cleanup()
    }
}
