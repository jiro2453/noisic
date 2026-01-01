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
        VStack(spacing: 20) {
            // Simple Vinyl Record
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 380, height: 380)

                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 310, height: 310)

                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 290, height: 290)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.4))
                    )

                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
            }

            Text("Music Player")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .opacity(0.55)
        }
    }
}
