//
//  MusicPlayerView.swift
//  Noisic
//
//  Created on 2025-12-31
//

import SwiftUI

struct MusicPlayerView: View {
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @State private var rotation: Double = 0

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Album Artwork as Vinyl Record (Large)
            VinylRecordView(
                artwork: musicInfoReader.musicInfo.artwork,
                isRotating: musicInfoReader.isPlaying,
                rotation: $rotation
            )

            // Song Info
            VStack(spacing: 4) {
                Text(musicInfoReader.musicInfo.title ?? "Unknown Track")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)

                Text(musicInfoReader.musicInfo.artist ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            .frame(maxWidth: 300)
            .opacity(0.55)
            .allowsHitTesting(false)

            // Time Display
            HStack {
                Text(formatTime(musicInfoReader.currentTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text(formatTime(musicInfoReader.duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 300)
            .opacity(musicInfoReader.musicInfo.title != nil ? 0.5 : 0.2)
            .allowsHitTesting(false)
            .padding(.horizontal, 10)

            // Playback Control Buttons
            HStack(spacing: 40) {
                // Previous Button
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        musicInfoReader.skipToPrevious()
                    }
                    .disabled(musicInfoReader.musicInfo.title == nil)

                // Play/Pause Button
                Image(systemName: musicInfoReader.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: musicInfoReader.isPlaying ? 0 : 2)
                    .frame(width: 60, height: 60)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        musicInfoReader.playPause()
                    }
                    .disabled(musicInfoReader.musicInfo.title == nil)

                // Next Button
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        musicInfoReader.skipToNext()
                    }
                    .disabled(musicInfoReader.musicInfo.title == nil)
            }
            .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 5)
            .opacity(musicInfoReader.musicInfo.title != nil ? 0.55 : 0.2)
        }
    }
}

struct VinylRecordView: View {
    let artwork: UIImage?
    let isRotating: Bool
    @Binding var rotation: Double
    @State private var rotationTimer: Timer?

    var body: some View {
        ZStack {
            // Vinyl Record Disc
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 380, height: 380)

            // Vinyl grooves (concentric circles)
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 362, height: 362)
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 344, height: 344)
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 326, height: 326)
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 308, height: 308)

            // Inner label area (darker)
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 310, height: 310)

            // Album artwork or placeholder
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 290, height: 290)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 290, height: 290)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.4))
                    )
            }

            // Center hole
            Circle()
                .fill(Color.black)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if isRotating {
                startRotation()
            }
        }
        .onDisappear {
            rotationTimer?.invalidate()
            rotationTimer = nil
        }
        .onChange(of: isRotating) { newValue in
            if newValue {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }

    private func startRotation() {
        rotationTimer?.invalidate()

        let degreesPerFrame = 30.0 / 60.0

        rotationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [self] _ in
            rotation += degreesPerFrame
            if rotation >= 360 {
                rotation -= 360
            }
        }
    }

    private func stopRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
}
