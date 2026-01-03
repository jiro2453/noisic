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

// 右下のモーダルトリガーUI
struct ModalTriggerView: View {
    @Binding var dragOffset: CGSize
    @Binding var showModal: Bool

    var body: some View {
        // モーダルの左上角を表示
        ZStack {
            // 背景の一部（モーダルのプレビュー）
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .frame(width: 120, height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                        Text("ライブラリ")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
                .offset(x: 40, y: 40) // 右下に少しはみ出すように
        }
        .frame(width: 80, height: 80)
        .clipped()
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 左上方向へのドラッグのみ許可
                    let newX = min(0, value.translation.width)
                    let newY = min(0, value.translation.height)
                    dragOffset = CGSize(width: newX, height: newY)
                }
                .onEnded { value in
                    // 一定以上ドラッグしたらモーダルを表示
                    if value.translation.width < -100 || value.translation.height < -100 {
                        showModal = true
                    }
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
        )
    }
}
