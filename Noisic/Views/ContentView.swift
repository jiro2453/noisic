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
    @State private var dragOffset: CGFloat = 0

    private var extendedSounds: [AmbientSound] {
        AmbientSound.allCases + AmbientSound.allCases + AmbientSound.allCases
    }

    private var actualIndex: Int {
        currentIndex % AmbientSound.allCases.count
    }

    var body: some View {
        ZStack {
            // ビデオ背景
            VideoPlayerView(videoName: AmbientSound.allCases[actualIndex].videoFileName)
                .ignoresSafeArea()
                .id(currentIndex) // indexが変わったらビデオを再作成

            // グラデーションオーバーレイ
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

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

                // スワイプ指示
                Text("← スワイプして切り替え →")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 20)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50

                    if value.translation.width > threshold {
                        // 右スワイプ（前へ）
                        withAnimation {
                            currentIndex = (currentIndex - 1 + extendedSounds.count) % extendedSounds.count
                        }
                        handleIndexChange()
                    } else if value.translation.width < -threshold {
                        // 左スワイプ（次へ）
                        withAnimation {
                            currentIndex = (currentIndex + 1) % extendedSounds.count
                        }
                        handleIndexChange()
                    }

                    dragOffset = 0
                }
        )
        .onAppear {
            // Auto-play bonfire on launch
            if !audioManager.isPlaying {
                audioManager.play(sound: .bonfire)
            }
        }
    }

    private func handleIndexChange() {
        // Auto-play ambient sound when swiping
        let sound = extendedSounds[currentIndex]
        audioManager.play(sound: sound)

        // Handle infinite loop by jumping to middle set
        let count = AmbientSound.allCases.count
        if currentIndex <= 1 {
            DispatchQueue.main.async {
                currentIndex = currentIndex + count
            }
        } else if currentIndex >= (count * 3) - 2 {
            DispatchQueue.main.async {
                currentIndex = currentIndex - count
            }
        }
    }
}
