//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

// iOS 16+ ハーフモーダル対応
struct HalfModalModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white.opacity(0.7))
        } else if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .background(Color.white.opacity(0.7))
        } else {
            content
                .background(Color.white.opacity(0.7))
        }
    }
}

// Custom Slider with full-width track (Float version)
struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 20
    let barWidth: CGFloat = 180

    var body: some View {
        let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let thumbOffset = percentage * barWidth

        ZStack(alignment: .leading) {
            // Background track
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: barWidth, height: trackHeight)
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
        .frame(width: barWidth + 40, height: 60)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    // フレームの左右20ptのパディングを考慮
                    let adjustedX = gesture.location.x - 20
                    let newPercentage = min(max(adjustedX / barWidth, 0), 1)
                    let newValue = range.lowerBound + Float(newPercentage) * (range.upperBound - range.lowerBound)
                    value = newValue
                }
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var storeManager: StoreManager
    @State private var currentIndex = 6
    @State private var showLibraryModal = false
    @State private var showPaywall = false

    private var extendedSounds: [AmbientSound] {
        AmbientSound.allCases + AmbientSound.allCases + AmbientSound.allCases
    }

    private var actualIndex: Int {
        currentIndex % AmbientSound.allCases.count
    }

    private var currentSound: AmbientSound {
        AmbientSound.allCases[actualIndex]
    }

    private var isCurrentSoundLocked: Bool {
        !storeManager.isUnlocked(currentSound)
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

            // ロック時の追加オーバーレイ
            if isCurrentSoundLocked {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

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

                        ZStack {
                            Image(systemName: currentSound.icon)
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .opacity(isCurrentSoundLocked ? 0.3 : 0.55)

                            // ロックアイコン
                            if isCurrentSoundLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .offset(x: 20, y: 15)
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(0.4)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .overlay(
                        // アンロックボタン（アイコンの上に固定配置）
                        Group {
                            if isCurrentSoundLocked {
                                Button(action: {
                                    showPaywall = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lock.open.fill")
                                            .font(.system(size: 12))
                                        Text("unlock")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .offset(y: -50),
                        alignment: .top
                    )

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
                            range: 0...4
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

                // Music Player
                MusicPlayerView(showLibraryModal: $showLibraryModal)
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)
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
        .sheet(isPresented: $showLibraryModal) {
            LibraryModalView(isPresented: $showLibraryModal) { album in
                libraryManager.playAlbum(album)
            }
            .environmentObject(libraryManager)
            .modifier(HalfModalModifier())
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, targetSound: currentSound)
                .environmentObject(storeManager)
        }
    }

    private func handleIndexChange() {
        let sound = extendedSounds[currentIndex]

        // ロックされているサウンドの場合は音声を停止
        if !storeManager.isUnlocked(sound) {
            audioManager.stop()
        } else {
            audioManager.play(sound: sound)
        }

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
