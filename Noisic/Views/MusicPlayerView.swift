//
//  MusicPlayerView.swift
//  Noisic
//
//  Created on 2025-12-31
//

import SwiftUI

// Seek bar with same style as CustomSlider (white theme)
struct SeekBar: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void

    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 20
    let barWidth: CGFloat = 280

    @State private var isDragging = false

    var body: some View {
        let percentage = range.upperBound > range.lowerBound
            ? CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            : 0
        let clampedPercentage = min(max(percentage, 0), 1)
        let thumbOffset = clampedPercentage * barWidth

        ZStack(alignment: .leading) {
            // Background track (same as CustomSlider)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: barWidth, height: trackHeight)
                .cornerRadius(trackHeight / 2)

            // Active track (same as CustomSlider)
            Rectangle()
                .fill(Color.white)
                .frame(width: thumbOffset, height: trackHeight)
                .cornerRadius(trackHeight / 2)

            // Thumb (same as CustomSlider)
            Circle()
                .fill(Color.gray)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: thumbOffset - thumbSize / 2)
        }
        .frame(width: barWidth, height: 44)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        onEditingChanged(true)
                    }
                    let newPercentage = min(max(gesture.location.x / barWidth, 0), 1)
                    let newValue = range.lowerBound + Double(newPercentage) * (range.upperBound - range.lowerBound)
                    value = newValue
                }
                .onEnded { _ in
                    isDragging = false
                    onEditingChanged(false)
                }
        )
    }
}

// Rotating vinyl record view
struct VinylRecordView: View {
    let artwork: UIImage?
    let isPlaying: Bool

    @State private var rotationAngle: Double = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 330, height: 330)

            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 280, height: 280)

            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 260, height: 260)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(rotationAngle))
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 260, height: 260)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 70))
                            .foregroundColor(.white.opacity(0.4))
                    )
                    .rotationEffect(.degrees(rotationAngle))
            }

            Circle()
                .fill(Color.black)
                .frame(width: 35, height: 35)
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startRotation()
            } else {
                stopRotation()
            }
        }
        .onAppear {
            if isPlaying {
                startRotation()
            }
        }
        .onDisappear {
            stopRotation()
        }
    }

    private func startRotation() {
        // 既にタイマーが動いている場合は何もしない
        guard timer == nil else { return }

        // 60fpsで回転（1回転8秒 = 45度/秒 = 0.75度/フレーム）
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            withAnimation(.linear(duration: 1.0/60.0)) {
                rotationAngle += 0.75
            }
        }
    }

    private func stopRotation() {
        timer?.invalidate()
        timer = nil
    }
}

// 六角形の形状（ライブラリボタン用）
struct HexagonButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct MusicPlayerView: View {
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @Binding var showLibraryModal: Bool
    @State private var isSeeking = false
    @State private var seekValue: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            // Album Artwork / Vinyl Record
            VinylRecordView(
                artwork: musicInfoReader.musicInfo.artwork,
                isPlaying: musicInfoReader.isPlaying
            )
            .offset(y: -20)

            // Song Info
            VStack(spacing: 4) {
                Text(musicInfoReader.musicInfo.title ?? "No song playing")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(musicInfoReader.musicInfo.artist ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.top, 8)

            // Seek Bar
            VStack(spacing: 4) {
                SeekBar(
                    value: Binding(
                        get: { isSeeking ? seekValue : musicInfoReader.currentTime },
                        set: { seekValue = $0 }
                    ),
                    range: 0...max(musicInfoReader.duration, 1),
                    onEditingChanged: { editing in
                        isSeeking = editing
                        if !editing {
                            musicInfoReader.seek(to: seekValue)
                        }
                    }
                )

                // Time Labels
                HStack {
                    Text(formatTime(isSeeking ? seekValue : musicInfoReader.currentTime))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    Text(formatTime(musicInfoReader.duration))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(width: 280)
            }

            // Playback Controls
            ZStack {
                // 中央の再生コントロール
                HStack(spacing: 40) {
                    Button(action: {
                        musicInfoReader.skipToPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Button(action: {
                        musicInfoReader.playPause()
                    }) {
                        Image(systemName: musicInfoReader.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                    }

                    Button(action: {
                        musicInfoReader.skipToNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // 右側の六角形ボタン
                HStack {
                    Spacer()
                    Button(action: {
                        showLibraryModal = true
                    }) {
                        HexagonButtonShape()
                            .stroke(Color.white.opacity(0.6), lineWidth: 3)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
