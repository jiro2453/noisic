//
//  MusicPlayerView.swift
//  Noisic
//
//  Created on 2025-12-31
//

import SwiftUI

struct MusicPlayerView: View {
    @EnvironmentObject var musicInfoReader: MusicInfoReader

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Album Artwork as Vinyl Record (Large, Static)
            ZStack {
                // Vinyl Record Disc
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 380, height: 380)

                // Inner label area
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 310, height: 310)

                // Album artwork or placeholder
                if let artwork = musicInfoReader.musicInfo.artwork {
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
            .padding(.horizontal, 10)

            // Playback Control Buttons
            HStack(spacing: 40) {
                // Previous Button
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        if musicInfoReader.musicInfo.title != nil {
                            musicInfoReader.skipToPrevious()
                        }
                    }

                // Play/Pause Button
                Image(systemName: musicInfoReader.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: musicInfoReader.isPlaying ? 0 : 2)
                    .frame(width: 60, height: 60)
                    .onTapGesture {
                        if musicInfoReader.musicInfo.title != nil {
                            musicInfoReader.playPause()
                        }
                    }

                // Next Button
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        if musicInfoReader.musicInfo.title != nil {
                            musicInfoReader.skipToNext()
                        }
                    }
            }
            .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 5)
            .opacity(musicInfoReader.musicInfo.title != nil ? 0.55 : 0.2)
        }
    }
}
