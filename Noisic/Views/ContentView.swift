//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

// Custom Slider with full-width track (Float version)
struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 20

    var body: some View {
        let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let thumbOffset = percentage * 180 // Fixed width

        ZStack(alignment: .leading) {
            // Background track
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 180, height: trackHeight)
                .cornerRadius(trackHeight / 2)

            // Active track
            Rectangle()
                .fill(Color.white)
                .frame(width: thumbOffset, height: trackHeight)
                .cornerRadius(trackHeight / 2)

            // Thumb
            Circle()
                .fill(Color.gray)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: thumbOffset - thumbSize / 2)
        }
        .frame(width: 180, height: 44)
    }
}

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
            // ビデオ背景（有効化してテスト）
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

                    // Volume Control
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .opacity(0.5)

                        CustomSlider(
                            value: Binding(
                                get: { audioManager.volume },
                                set: { audioManager.setVolume($0) }
                            ),
                            range: 1...4
                        )

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
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
            print("DEBUG: ContentView onAppear")
            audioManager.play(sound: .bonfire)
            print("DEBUG: audioManager.play called")
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
