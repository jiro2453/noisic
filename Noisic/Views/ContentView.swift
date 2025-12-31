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
        GeometryReader { geometry in
            let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbOffset = percentage * geometry.size.width

            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: trackHeight)
                    .cornerRadius(trackHeight / 2)

                // Active track (from left edge to thumb center)
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
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newPercentage = max(0, min(1, gesture.location.x / geometry.size.width))
                        let newValue = Float(newPercentage) * (range.upperBound - range.lowerBound) + range.lowerBound
                        value = newValue
                    }
            )
        }
        .frame(height: 44)
    }
}

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var currentIndex = 11 // Start from bonfire in middle of tripled array (6+5)

    // Triple the ambient sounds for infinite scrolling effect
    private var extendedSounds: [AmbientSound] {
        AmbientSound.allCases + AmbientSound.allCases + AmbientSound.allCases
    }

    private var actualIndex: Int {
        currentIndex % AmbientSound.allCases.count
    }

    var body: some View {
        ZStack {
            // Background Video Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(extendedSounds.enumerated()), id: \.offset) { index, sound in
                    VideoPlayerView(videoName: sound.videoFileName)
                        .tag(index)
                        .id(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: currentIndex) { newValue in
                // Auto-play ambient sound when swiping
                let sound = extendedSounds[newValue]
                audioManager.play(sound: sound)

                // Handle infinite loop by jumping to middle set
                let count = AmbientSound.allCases.count
                if newValue <= 1 {
                    DispatchQueue.main.async {
                        currentIndex = newValue + count
                    }
                } else if newValue >= (count * 3) - 2 {
                    DispatchQueue.main.async {
                        currentIndex = newValue - count
                    }
                }
            }

            // Gradient overlay
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
                    .allowsHitTesting(false)

                    // Volume Control
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .opacity(0.6)

                        CustomSlider(value: $audioManager.volume, range: 0...1)
                            .frame(width: 150)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .opacity(0.6)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 60)
                .frame(maxHeight: 30)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Auto-play bonfire on launch
            if !audioManager.isPlaying {
                audioManager.play(sound: .bonfire)
            }
        }
    }
}
