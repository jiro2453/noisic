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
            // Using .playback with .mixWithOthers to ignore silent switch
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )

            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Silently handle error
        }
    }
}
