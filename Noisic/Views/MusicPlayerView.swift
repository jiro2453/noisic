//
//  MusicPlayerView.swift
//  Noisic
//
//  Created on 2025-12-31
//

import SwiftUI

struct MusicPlayerView: View {
    @EnvironmentObject var musicInfoReader: MusicInfoReader

    var body: some View {
        VStack(spacing: 8) {
            // Album artwork
            if let artwork = musicInfoReader.musicInfo.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.5), radius: 15)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 180)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .shadow(color: .black.opacity(0.5), radius: 15)
            }

            // Song info
            VStack(spacing: 4) {
                if let title = musicInfoReader.musicInfo.title {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else {
                    Text("No Music Playing")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }

                if let artist = musicInfoReader.musicInfo.artist {
                    Text(artist)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)

            // Time display
            HStack(spacing: 8) {
                Text(formatTime(musicInfoReader.currentTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text("/")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))

                Text(formatTime(musicInfoReader.duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 4)

            // Playback controls
            HStack(spacing: 40) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .opacity(0.8)
                    .onTapGesture {
                        musicInfoReader.skipToPrevious()
                    }

                Image(systemName: musicInfoReader.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.white)
                    .onTapGesture {
                        musicInfoReader.playPause()
                    }

                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .opacity(0.8)
                    .onTapGesture {
                        musicInfoReader.skipToNext()
                    }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .shadow(color: .black.opacity(0.5), radius: 20)
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
