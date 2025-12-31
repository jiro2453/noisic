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

                // デバッグ情報
                VStack(spacing: 4) {
                    Text(audioManager.isPlaying ? "🔊 再生中" : "🔇 停止中")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Index: \(currentIndex)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Drag: \(Int(dragOffset))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    dragOffset = value.translation.width
                    print("👆 Dragging: \(dragOffset)")
                }
                .onEnded { value in
                    let threshold: CGFloat = 30 // 閾値を下げた

                    print("✋ Drag ended: \(value.translation.width)")

                    if value.translation.width > threshold {
                        // 右スワイプ（前へ）
                        print("➡️ Swipe right detected")
                        currentIndex = (currentIndex - 1 + extendedSounds.count) % extendedSounds.count
                        handleIndexChange()
                    } else if value.translation.width < -threshold {
                        // 左スワイプ（次へ）
                        print("⬅️ Swipe left detected")
                        currentIndex = (currentIndex + 1) % extendedSounds.count
                        handleIndexChange()
                    }

                    dragOffset = 0
                }
        )
        .onAppear {
            print("📱 ContentView appeared, isPlaying: \(audioManager.isPlaying)")
            audioManager.play(sound: .bonfire)
            print("📱 Bonfire play called")
        }
    }

    private func handleIndexChange() {
        let sound = extendedSounds[currentIndex]
        print("🎵 Switching to: \(sound.rawValue), index: \(currentIndex)")
        audioManager.play(sound: sound)

        // Handle infinite loop by jumping to middle set
        let count = AmbientSound.allCases.count
        if currentIndex <= 1 {
            DispatchQueue.main.async {
                currentIndex = currentIndex + count
                print("🔄 Jump to middle from start: \(currentIndex)")
            }
        } else if currentIndex >= (count * 3) - 2 {
            DispatchQueue.main.async {
                currentIndex = currentIndex - count
                print("🔄 Jump to middle from end: \(currentIndex)")
            }
        }
    }
}
