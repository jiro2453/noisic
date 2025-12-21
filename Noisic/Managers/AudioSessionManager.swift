//
//  AudioSessionManager.swift
//  Noisic
//
//  Created on 2025-12-21
//

import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configure() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Set category to allow mixing with other audio (like music apps)
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )

            try audioSession.setActive(true)

            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
