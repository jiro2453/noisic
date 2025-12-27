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

    private var audioPlayer: AVAudioPlayer?

    func play(sound: AmbientSound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            return
        }

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            // Apply volume multiplier for each sound
            audioPlayer?.volume = volume * sound.volumeMultiplier
            audioPlayer?.prepareToPlay()

            let success = audioPlayer?.play() ?? false

            currentSound = sound
            isPlaying = success
        } catch {
            // Silently handle error
        }
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentSound = nil
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        // Apply volume multiplier when changing volume
        if let sound = currentSound {
            audioPlayer?.volume = newVolume * sound.volumeMultiplier
        } else {
            audioPlayer?.volume = newVolume
        }
    }
}
