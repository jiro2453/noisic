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
            // Using .ambient category instead of .playback for better mixing behavior
            try audioSession.setCategory(
                .ambient,
                mode: .default,
                options: []
            )

            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            print("Audio session configured successfully with category: \(audioSession.category)")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func ensureActive() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true)
            }
        } catch {
            print("Failed to ensure audio session active: \(error.localizedDescription)")
        }
    }
}
