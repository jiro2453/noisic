//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var currentIndex = 11

    private var extendedSounds: [AmbientSound] {
        AmbientSound.allCases + AmbientSound.allCases + AmbientSound.allCases
    }

    private var actualIndex: Int {
        currentIndex % AmbientSound.allCases.count
    }

    var body: some View {
        ZStack {
            // シンプルな背景色のみ（VideoPlayerViewは使わない）
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Noisic")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)

                // 現在の環境音を表示
                Text(AmbientSound.allCases[actualIndex].rawValue)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))

                // アイコン表示
                Image(systemName: AmbientSound.allCases[actualIndex].icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .opacity(0.6)
            }
        }
        .onAppear {
            // Auto-play bonfire on launch
            if !audioManager.isPlaying {
                audioManager.play(sound: .bonfire)
            }
        }
    }
}
