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

    let minHeight: CGFloat = 100 // Handle only (circular peek)
    let maxHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Handle Area
                if isExpanded {
                    // Expanded: Traditional handle
                    HStack {
                        Spacer()

                        VStack(spacing: 8) {
                            // Drag Handle
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 40, height: 6)
                                .padding(.top, 12)

                            Text("ライブラリ")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Spacer()
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7))
                    .gesture(dragGesture(geometry: geometry))
                } else {
                    // Collapsed: Circular peek from bottom-right corner
                    ZStack {
                        // Large circle (mostly off-screen)
                        Circle()
                            .fill(Color.gray.opacity(0.85))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                                    .offset(x: -25, y: -25)
                            )
                            .offset(x: 20, y: 20) // Position so top-left portion is more visible
                    }
                    .frame(width: 100, height: 100, alignment: .topLeading)
                    .frame(maxWidth: .infinity, maxHeight: 100, alignment: .bottomTrailing)
                    .gesture(dragGesture(geometry: geometry))
                }

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
                                                            offset = geometry.size.height - minHeight
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
                                                        offset = geometry.size.height - minHeight
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
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                RoundedRectangle(cornerRadius: isExpanded ? 20 : 0)
                    .fill(Color.black.opacity(isExpanded ? 0.7 : 0.0))
                    .shadow(color: .black.opacity(isExpanded ? 0.5 : 0), radius: 20, y: -5)
            )
            .offset(y: offset)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea()
    }

    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = offset + value.translation.height
                let minY = geometry.size.height - maxHeight
                let maxY = geometry.size.height - minHeight
                // Limit dragging between fully expanded and collapsed
                offset = max(minY, min(maxY, newOffset))
            }
            .onEnded { value in
                // Snap to positions
                let minY = geometry.size.height - maxHeight
                let maxY = geometry.size.height - minHeight
                let midY = (minY + maxY) / 2

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if offset < midY {
                        // Expand (closer to top)
                        offset = minY
                        isExpanded = true
                    } else {
                        // Collapse (closer to bottom)
                        offset = maxY
                        isExpanded = false
                    }
                }
            }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
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
