//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var musicInfoReader: MusicInfoReader
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

            // Foreground Content
            VStack(spacing: 0) {
                // Ambient Sound Icon with Navigation Arrows at Top
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
                }
                .padding(.top, 50)

                Spacer()
                    .frame(maxHeight: 30)

                // Music Player Section (Upper Center)
                MusicPlayerView()

                Spacer()

                // Debug: Show current index
                Text("Index: \(currentIndex) / Actual: \(actualIndex)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .allowsHitTesting(false)
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
