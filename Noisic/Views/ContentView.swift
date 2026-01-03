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

// 右下のモーダルトリガーUI
struct ModalTriggerView: View {
    @Binding var dragOffset: CGSize
    @Binding var showModal: Bool

    var body: some View {
        // モーダルの左上角を表示
        ZStack {
            // 背景の一部（モーダルのプレビュー）
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.8))
                .frame(width: 200, height: 200)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                        Text("ライブラリ")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                    }
                )
                .offset(x: 50, y: 50)
        }
        .frame(width: 150, height: 150)
        .clipped()
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 左上方向へのドラッグのみ許可
                    let newX = min(0, value.translation.width)
                    let newY = min(0, value.translation.height)
                    dragOffset = CGSize(width: newX, height: newY)
                }
                .onEnded { value in
                    // 一定以上ドラッグしたらモーダルを表示
                    if value.translation.width < -100 || value.translation.height < -100 {
                        showModal = true
                    }
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @EnvironmentObject var libraryManager: LibraryManager
    @State private var currentIndex = 11
    @State private var showLibraryModal = false
    @State private var modalDragOffset: CGSize = .zero

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

                // Music Player
                MusicPlayerView()
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)

            // 右下のモーダルトリガー
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ModalTriggerView(
                        dragOffset: $modalDragOffset,
                        showModal: $showLibraryModal
                    )
                }
            }
            .ignoresSafeArea()
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
        .fullScreenCover(isPresented: $showLibraryModal) {
            LibraryModalView(isPresented: $showLibraryModal) { album in
                libraryManager.playAlbum(album)
            }
            .environmentObject(libraryManager)
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
