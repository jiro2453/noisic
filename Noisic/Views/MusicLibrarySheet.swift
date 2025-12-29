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
                // Header/Handle Area
                HStack {
                    Spacer()

                    VStack(spacing: 8) {
                        // Drag Handle
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 6)
                            .padding(.top, 12)

                        if isExpanded {
                            Text("ライブラリ")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()
                }
                .frame(height: isExpanded ? 60 : 100)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottomTrailing) {
                    // Collapsed state: show icon in bottom-right
                    if !isExpanded {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.trailing, 35)
                            .padding(.bottom, 35)
                    }
                }
                .gesture(dragGesture(geometry: geometry))

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
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                // 右下角だけ大きく丸めたシート背景
                UnevenRoundedRectangle(
                    topLeadingRadius: isExpanded ? 20 : 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: isExpanded ? 0 : 60,
                    topTrailingRadius: isExpanded ? 20 : 0
                )
                .fill(Color.gray.opacity(isExpanded ? 0.85 : 0.3))
                .shadow(color: .black.opacity(isExpanded ? 0.5 : 0.2), radius: 20, y: -5)
            )
            .offset(y: offset)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea()
    }

    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // 上方向へのドラッグで展開
                let newOffset = offset + value.translation.height
                let minY = geometry.size.height - maxHeight
                let maxY = geometry.size.height - minHeight
                // ドラッグ範囲を制限
                offset = max(minY, min(maxY, newOffset))
            }
            .onEnded { value in
                let minY = geometry.size.height - maxHeight
                let maxY = geometry.size.height - minHeight

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    // 上にドラッグした場合
                    if value.translation.height < -50 {
                        offset = minY
                        isExpanded = true
                    }
                    // 下にドラッグした場合
                    else if value.translation.height > 50 {
                        offset = maxY
                        isExpanded = false
                    }
                    // 位置に基づいてスナップ
                    else {
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
