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
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.3))
                            .foregroundColor(.white.opacity(0.4))
                    )
            }
        }
    }
}

// ハニカムグリッドレイアウト
struct HoneycombGrid: View {
    let albums: [LibraryAlbum]
    let hexSize: CGFloat = 80
    let onAlbumTap: (LibraryAlbum) -> Void

    var body: some View {
        let horizontalSpacing = hexSize * 0.75
        let verticalSpacing = hexSize * 0.866 // sqrt(3)/2

        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(albums.prefix(30).enumerated()), id: \.element.id) { index, album in
                        let row = index / 5
                        let col = index % 5
                        let isOddRow = row % 2 == 1
                        let xOffset = CGFloat(col) * horizontalSpacing + (isOddRow ? horizontalSpacing / 2 : 0) + hexSize / 2
                        let yOffset = CGFloat(row) * verticalSpacing + hexSize / 2

                        Button(action: {
                            onAlbumTap(album)
                        }) {
                            HexagonArtwork(artwork: album.artwork, size: hexSize)
                        }
                        .position(x: xOffset, y: yOffset)
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: CGFloat((albums.prefix(30).count + 4) / 5) * verticalSpacing + hexSize
                )
            }
        }
    }
}

struct LibraryModalView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @Binding var isPresented: Bool
    let onAlbumSelected: (LibraryAlbum) -> Void

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("ライブラリ")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // アルバムグリッド
                if libraryManager.recentlyAdded.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.house")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.4))
                        Text("アルバムがありません")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                } else {
                    HoneycombGrid(albums: libraryManager.recentlyAdded) { album in
                        onAlbumSelected(album)
                        isPresented = false
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            libraryManager.checkAuthorization()
        }
    }
}

