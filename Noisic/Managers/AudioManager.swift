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
        NSLog("=== AudioManager initialized ===")
        print("=== AudioManager initialized ===")
    }

    func play(sound: AmbientSound) {
        NSLog("=== AudioManager.play() called for: %@", sound.displayName)
        print("=== AudioManager.play() called for: \(sound.displayName) ===")
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            NSLog("❌ ERROR: Audio file not found: %@", sound.fileName)
            print("❌ ERROR: Audio file not found: \(sound.fileName)")
            return
        }
        NSLog("✓ Audio file found at: %@", url.path)
        print("✓ Audio file found at: \(url.path)")

        do {
            audioPlayer?.stop()
            NSLog("Creating AVAudioPlayer...")
            print("Creating AVAudioPlayer...")
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = volume
            NSLog("Preparing to play...")
            print("Preparing to play...")
            audioPlayer?.prepareToPlay()

            NSLog("Calling play()...")
            print("Calling play()...")
            let success = audioPlayer?.play() ?? false

            currentSound = sound
            isPlaying = success

            if success {
                NSLog("✓ SUCCESS: Now playing '%@' at volume %.2f", sound.displayName, volume)
                print("✓ SUCCESS: Now playing '\(sound.displayName)' at volume \(volume)")
            } else {
                NSLog("❌ FAILED: play() returned false for '%@'", sound.displayName)
                print("❌ FAILED: play() returned false for '\(sound.displayName)'")
            }
        } catch {
            NSLog("❌ ERROR: Failed to play audio: %@", error.localizedDescription)
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
