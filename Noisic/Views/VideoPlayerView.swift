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
            .ignoresSafeArea()
    }
}

// UIViewControllerRepresentableを使用（UIViewRepresentableより安定）
struct VideoPlayerContainer: UIViewControllerRepresentable {
    let videoName: String

    func makeUIViewController(context: Context) -> VideoPlayerViewController {
        print("DEBUG: VideoPlayerContainer makeUIViewController")
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
    private var observer: NSObjectProtocol?

    init(videoName: String) {
        self.currentVideoName = videoName
        super.init(nibName: nil, bundle: nil)
        print("DEBUG: VideoPlayerViewController init - \(videoName)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("DEBUG: VideoPlayerViewController viewDidLoad")
        view.backgroundColor = .black

        // バックグラウンドスレッドで動画を読み込む
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadVideoAsync()
        }
    }

    private func loadVideoAsync() {
        guard let url = Bundle.main.url(forResource: currentVideoName, withExtension: "mp4") else {
            print("DEBUG: Video file NOT found: \(currentVideoName).mp4")
            return
        }

        print("DEBUG: Video file found: \(url)")

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

            // ブラー効果を追加
            let blurEffect = UIBlurEffect(style: .regular)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = self.view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.alpha = 0.3
            self.view.addSubview(blurView)

            // ループ再生
            self.observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }

            newPlayer.play()
            print("DEBUG: Video playing")
        }
    }

    func loadVideo(named name: String) {
        currentVideoName = name
        cleanup()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadVideoAsync()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    private func cleanup() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }

        observer = nil
        player = nil
        playerLayer = nil
    }

    deinit {
        cleanup()
        print("DEBUG: VideoPlayerViewController deinit")
    }
}
