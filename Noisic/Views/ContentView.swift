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
                .id(actualIndex)

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

            // テキスト表示レイヤー（ジェスチャーをブロックしない）
            VStack(spacing: 20) {
                Text("Noisic")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)

                Text(AmbientSound.allCases[actualIndex].rawValue)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))

                Image(systemName: AmbientSound.allCases[actualIndex].icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .opacity(0.6)

                Text("← スワイプして切り替え →")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 20)

                VStack(spacing: 4) {
                    Text(audioManager.isPlaying ? "🔊 再生中" : "🔇 停止中")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Index: \(currentIndex) / Actual: \(actualIndex)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Drag: \(Int(dragOffset))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
                    .frame(height: 60) // ボタン用のスペース
            }
            .allowsHitTesting(false) // ジェスチャーをブロックしない

            // ボタンレイヤー（別のZStackレイヤー）
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button("◀︎") {
                        print("🔘 Button tapped: Previous")
                        DispatchQueue.main.async {
                            currentIndex = (currentIndex - 1 + extendedSounds.count) % extendedSounds.count
                            print("📊 Button changed to: \(currentIndex)")
                            handleIndexChange()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)

                    Button("▶︎") {
                        print("🔘 Button tapped: Next")
                        DispatchQueue.main.async {
                            currentIndex = (currentIndex + 1) % extendedSounds.count
                            print("📊 Button changed to: \(currentIndex)")
                            handleIndexChange()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            // このレイヤーだけがボタンのタップを受け付ける
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    DispatchQueue.main.async {
                        dragOffset = value.translation.width
                    }
                    print("👆 Dragging: \(dragOffset)")
                }
                .onEnded { value in
                    let threshold: CGFloat = 30

                    print("✋ Drag ended: \(value.translation.width)")

                    if value.translation.width > threshold {
                        print("➡️ Swipe right detected")
                        DispatchQueue.main.async {
                            currentIndex = (currentIndex - 1 + extendedSounds.count) % extendedSounds.count
                            print("📊 New index: \(currentIndex), actualIndex: \(actualIndex)")
                            handleIndexChange()
                        }
                    } else if value.translation.width < -threshold {
                        print("⬅️ Swipe left detected")
                        DispatchQueue.main.async {
                            currentIndex = (currentIndex + 1) % extendedSounds.count
                            print("📊 New index: \(currentIndex), actualIndex: \(actualIndex)")
                            handleIndexChange()
                        }
                    }

                    DispatchQueue.main.async {
                        dragOffset = 0
                    }
                }
        )
        .onAppear {
            print("📱 ContentView appeared")
            print("📊 Initial index: \(currentIndex), actualIndex: \(actualIndex)")
            audioManager.play(sound: .bonfire)
            print("📱 Bonfire play called")
        }
    }

    private func handleIndexChange() {
        let sound = extendedSounds[currentIndex]
        print("🎵 Switching to: \(sound.rawValue), currentIndex: \(currentIndex), actualIndex: \(actualIndex)")
        audioManager.play(sound: sound)

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
