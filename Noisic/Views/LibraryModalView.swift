//
//  LibraryModalView.swift
//  Noisic
//
//  Created on 2025-01-03
//

import SwiftUI

// 6角形の形状
struct HexagonShape: Shape {
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

// 6角形アートワーク
struct HexagonArtwork: View {
    let artwork: UIImage?
    let size: CGFloat

    var body: some View {
        Group {
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(HexagonShape())
            } else {
                HexagonShape()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.3))
                            .foregroundColor(.black.opacity(0.3))
                    )
            }
        }
    }
}

// ハニカムグリッドレイアウト
struct HoneycombGrid: View {
    let albums: [LibraryAlbum]
    let onAlbumTap: (LibraryAlbum) -> Void

    var body: some View {
        GeometryReader { geometry in
            let hexSize = geometry.size.width / 4.0
            // 六角形が重ならない正しいスペーシング
            let horizontalSpacing = hexSize * 0.866
            let verticalSpacing = hexSize * 0.75

            // アルバムを行ごとに分割（奇数行4枚、偶数行5枚）
            let rowData = calculateRows(albums: Array(albums.prefix(49)))

            ScrollView {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(rowData.enumerated()), id: \.offset) { rowIndex, rowAlbums in
                        let isEvenRow = rowIndex % 2 == 1
                        let itemCount = isEvenRow ? 5 : 4
                        let rowWidth = CGFloat(itemCount - 1) * horizontalSpacing + hexSize
                        let startX = (geometry.size.width - rowWidth) / 2 + hexSize / 2

                        ForEach(Array(rowAlbums.enumerated()), id: \.element.id) { colIndex, album in
                            let xOffset = startX + CGFloat(colIndex) * horizontalSpacing
                            let yOffset = CGFloat(rowIndex) * verticalSpacing + hexSize / 2

                            HexagonArtwork(artwork: album.artwork, size: hexSize)
                                .position(x: xOffset, y: yOffset)
                                .onTapGesture {
                                    onAlbumTap(album)
                                }
                        }
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: CGFloat(rowData.count) * verticalSpacing + hexSize
                )
            }
        }
    }

    // アルバムを行ごとに分割（奇数行4枚、偶数行5枚）
    private func calculateRows(albums: [LibraryAlbum]) -> [[LibraryAlbum]] {
        var rows: [[LibraryAlbum]] = []
        var currentIndex = 0
        var rowIndex = 0

        while currentIndex < albums.count {
            let itemCount = (rowIndex % 2 == 0) ? 4 : 5
            let endIndex = min(currentIndex + itemCount, albums.count)
            rows.append(Array(albums[currentIndex..<endIndex]))
            currentIndex = endIndex
            rowIndex += 1
        }

        return rows
    }
}

struct LibraryModalView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @Binding var isPresented: Bool
    let onAlbumSelected: (LibraryAlbum) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー（中央配置）
            Text("Library")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // アルバムグリッド
            if libraryManager.combinedAlbums.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.note.house")
                        .font(.system(size: 48))
                        .foregroundColor(.black.opacity(0.3))
                    Text("No albums")
                        .foregroundColor(.black.opacity(0.5))
                }
                Spacer()
            } else {
                HoneycombGrid(albums: libraryManager.combinedAlbums) { album in
                    onAlbumSelected(album)
                    isPresented = false
                }
            }
        }
        .onAppear {
            libraryManager.checkAuthorization()
        }
    }
}

