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

            // UIレイヤー（スワイプを妨げない）
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    // Icon with Arrows
                    HStack(spacing: 20) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(0.4)

                        Image(systemName: AmbientSound.allCases[actualIndex].icon)
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .opacity(0.55)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(0.4)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)

                    // 音量インジケーター（視覚的表示のみ）
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .opacity(0.5)

                        HStack(spacing: 3) {
                            ForEach(1...4, id: \.self) { level in
                                Circle()
                                    .fill(audioManager.volume >= Float(level) ? Color.white : Color.white.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }
                        }

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .opacity(0.5)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 5)
                }
                .padding(.top, 50)

                Spacer()
            }
            .padding(.horizontal, 20)
            .allowsHitTesting(false)

            // 音量コントロールボタンレイヤー（別レイヤーで配置）
            VStack {
                Spacer()
                HStack(spacing: 15) {
                    // 音量ダウンボタン
                    Button(action: {
                        let newVolume = max(1.0, audioManager.volume - 1.0)
                        audioManager.setVolume(newVolume)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .opacity(0.7)
                            .shadow(color: .black.opacity(0.5), radius: 5)
                    }

                    // 音量アップボタン
                    Button(action: {
                        let newVolume = min(4.0, audioManager.volume + 1.0)
                        audioManager.setVolume(newVolume)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .opacity(0.7)
                            .shadow(color: .black.opacity(0.5), radius: 5)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let threshold: CGFloat = 30

                    if value.translation.width > threshold {
                        DispatchQueue.main.async {
                            currentIndex = (currentIndex - 1 + extendedSounds.count) % extendedSounds.count
                            handleIndexChange()
                        }
                    } else if value.translation.width < -threshold {
                        DispatchQueue.main.async {
                            currentIndex = (currentIndex + 1) % extendedSounds.count
                            handleIndexChange()
                        }
                    }
                }
        )
        .onAppear {
            audioManager.play(sound: .bonfire)
        }
    }

    private func handleIndexChange() {
        let sound = extendedSounds[currentIndex]
        audioManager.play(sound: sound)

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
