//
//  MusicLibrarySheet.swift
//  Noisic
//
//  Created on 2025-12-27
//

import SwiftUI

struct MusicLibrarySheet: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header/Handle Area
            HStack {
                Spacer()
                if isExpanded {
                    Text("ライブラリ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .frame(height: 60)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
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
            }
        }
        .frame(width: isExpanded ? UIScreen.main.bounds.width : 70,
               height: isExpanded ? UIScreen.main.bounds.height * 0.7 : 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(isExpanded ? 0.85 : 0.3))
                .shadow(color: .black.opacity(isExpanded ? 0.5 : 0.2), radius: 20, y: -5)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            libraryManager.checkAuthorization()
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
