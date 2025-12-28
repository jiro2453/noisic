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
                        // Large circle (mostly off-screen) - transparent
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
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
                            // Recently Added Albums
                            if !libraryManager.recentlyAdded.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(libraryManager.recentlyAdded.prefix(20)) { album in
                                            AlbumThumbnail(album: album)
                                                .onTapGesture {
                                                    libraryManager.playAlbum(album)
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        offset = geometry.size.height - minHeight
                                                        isExpanded = false
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .padding(.top, 16)
                            }

                            // All Albums
                            if !libraryManager.allAlbums.isEmpty {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(libraryManager.allAlbums.prefix(30)) { album in
                                        AlbumThumbnail(album: album)
                                            .onTapGesture {
                                                libraryManager.playAlbum(album)
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    offset = geometry.size.height - minHeight
                                                    isExpanded = false
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
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
                // Calculate diagonal drag (left-up direction)
                let diagonalDistance = -(value.translation.x + value.translation.y) / 2
                let newOffset = offset - diagonalDistance
                let minY = geometry.size.height - maxHeight
                let maxY = geometry.size.height - minHeight
                // Limit dragging between fully expanded and collapsed
                offset = max(minY, min(maxY, newOffset))
            }
            .onEnded { value in
                // Check if dragged left-up (negative x and negative y)
                let draggedLeftUp = value.translation.x < -30 || value.translation.y < -30

                let minY = geometry.size.height - maxHeight
                let maxY = geometry.size.height - minHeight

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if draggedLeftUp && !isExpanded {
                        // Expand when dragged left-up
                        offset = minY
                        isExpanded = true
                    } else if isExpanded && (value.translation.x > 30 || value.translation.y > 30) {
                        // Collapse when dragged right-down
                        offset = maxY
                        isExpanded = false
                    } else {
                        // Snap based on current position
                        let midY = (minY + maxY) / 2
                        if offset < midY {
                            offset = minY
                            isExpanded = true
                        } else {
                            offset = maxY
                            isExpanded = false
                        }
                    }
                }
            }
    }
}

struct AlbumThumbnail: View {
    let album: LibraryAlbum

    var body: some View {
        if let artwork = album.artwork {
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
    }
}
