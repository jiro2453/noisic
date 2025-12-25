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
    @Published var volume: Float = 1.0

    private var audioPlayer: AVAudioPlayer?

    init() {
        print("=== AudioManager initialized ===")
    }

    func play(sound: AmbientSound) {
        print("=== AudioManager.play() called for: \(sound.displayName) ===")
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            print("❌ ERROR: Audio file not found: \(sound.fileName)")
            return
        }
        print("✓ Audio file found at: \(url.path)")

        do {
            audioPlayer?.stop()
            print("Creating AVAudioPlayer...")
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = volume
            print("Preparing to play...")
            audioPlayer?.prepareToPlay()

            print("Calling play()...")
            let success = audioPlayer?.play() ?? false

            currentSound = sound
            isPlaying = success

            if success {
                print("✓ SUCCESS: Now playing '\(sound.displayName)' at volume \(volume)")
            } else {
                print("❌ FAILED: play() returned false for '\(sound.displayName)'")
            }
        } catch {
            print("❌ ERROR: Failed to play audio: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentSound = nil
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioPlayer?.volume = newVolume
    }
}
