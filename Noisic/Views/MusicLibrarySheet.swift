//
//  MusicLibrarySheet.swift
//  Noisic
//
//  Created on 2025-12-27
//

import SwiftUI

struct MusicLibrarySheet: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @Binding var offset: CGFloat
    @Binding var isExpanded: Bool

    let minHeight: CGFloat = 60 // Handle only
    let maxHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Handle Area
                VStack(spacing: 8) {
                    // Drag Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 40, height: 6)
                        .padding(.top, 12)

                    Text("ライブラリ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(isExpanded ? 1 : 0)
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newOffset = offset + value.translation.height
                            // Limit dragging
                            if newOffset >= 0 && newOffset <= maxHeight - minHeight {
                                offset = newOffset
                            }
                        }
                        .onEnded { value in
                            // Snap to positions
                            let threshold = maxHeight * 0.3
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if offset < threshold {
                                    // Expand
                                    offset = 0
                                    isExpanded = true
                                } else {
                                    // Collapse
                                    offset = maxHeight - minHeight
                                    isExpanded = false
                                }
                            }
                        }
                )

                // Content Area
                if isExpanded {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Recently Added
                            if !libraryManager.recentlyAdded.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("最近追加")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(libraryManager.recentlyAdded.prefix(20)) { track in
                                                TrackThumbnail(track: track)
                                                    .onTapGesture {
                                                        libraryManager.playTrack(track)
                                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                            offset = maxHeight - minHeight
                                                            isExpanded = false
                                                        }
                                                    }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // All Songs
                            if !libraryManager.allSongs.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("すべての曲")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)

                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(libraryManager.allSongs.prefix(30)) { track in
                                            TrackThumbnail(track: track)
                                                .onTapGesture {
                                                    libraryManager.playTrack(track)
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        offset = maxHeight - minHeight
                                                        isExpanded = false
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            // No Library Access
                            if !libraryManager.isAuthorized {
                                VStack(spacing: 16) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.6))

                                    Text("ライブラリへのアクセスが必要です")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))

                                    Text("設定からメディアライブラリへのアクセスを許可してください")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: isExpanded ? 20 : 10)
                    .fill(Color.black.opacity(0.7))
                    .shadow(color: .black.opacity(0.5), radius: 20, y: -5)
            )
            .offset(y: geometry.size.height - minHeight + offset)
        }
        .ignoresSafeArea()
    }
}

struct TrackThumbnail: View {
    let track: LibraryTrack

    var body: some View {
        VStack(spacing: 6) {
            if let artwork = track.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }

            Text(track.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 100)

            if let artist = track.artist {
                Text(artist)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 100)
            }
        }
    }
}
