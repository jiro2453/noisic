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

    func play(sound: AmbientSound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            return
        }

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = volume
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
        audioPlayer?.volume = newVolume
    }
}
