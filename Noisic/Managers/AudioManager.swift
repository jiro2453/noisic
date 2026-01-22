//
//  AudioManager.swift
//  Noisic
//
//  Created on 2025-12-21
//

import AVFoundation
import Combine

class AudioManager: ObservableObject {
    @Published var currentSound: AmbientSound?
    @Published var isPlaying = false
    @Published var volume: Float = 2.5

    // AVAudioEngineを使用して1.0以上の音量ブーストを可能に
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?

    // 環境音の基本ゲイン（音楽に対して大きくするため）
    private let baseGain: Float = 3.0

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)
    }

    func play(sound: AmbientSound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            return
        }

        do {
            // 既存の再生を停止
            stop()

            // AudioEngineを再セットアップ
            setupAudioEngine()

            guard let engine = audioEngine, let player = playerNode else { return }

            audioFile = try AVAudioFile(forReading: url)
            guard let file = audioFile else { return }

            let format = file.processingFormat

            // Mixerに接続（音量調整用）
            let mixer = engine.mainMixerNode
            engine.connect(player, to: mixer, format: format)

            // 音量を設定（baseGain × volumeMultiplier × ユーザー音量）
            let effectiveVolume = (volume / 4.0) * sound.volumeMultiplier * baseGain
            mixer.outputVolume = min(effectiveVolume, 30.0) // 最大30.0まで許可

            // エンジン開始
            try engine.start()

            // ループ再生をスケジュール
            scheduleLoop(file: file)

            player.play()

            currentSound = sound
            isPlaying = true
        } catch {
            // エラー時はサイレントに処理
        }
    }

    private func scheduleLoop(file: AVAudioFile) {
        guard let player = playerNode else { return }

        player.scheduleFile(file, at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.isPlaying else { return }
                // ファイル位置をリセットしてループ
                file.framePosition = 0
                self.scheduleLoop(file: file)
            }
        }
    }

    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
        currentSound = nil
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume

        guard let engine = audioEngine, let sound = currentSound else { return }

        // 音量を更新
        let effectiveVolume = (newVolume / 4.0) * sound.volumeMultiplier * baseGain
        engine.mainMixerNode.outputVolume = min(effectiveVolume, 30.0)
    }
}
