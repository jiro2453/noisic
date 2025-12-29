//
//  MusicLibrarySheet.swift
//  Noisic
//
//  Created on 2025-12-27
//

import SwiftUI

struct MusicLibrarySheet: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                LibraryContentView()
            }
        }
        .frame(width: isExpanded ? 390 : 70,
               height: isExpanded ? 600 : 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(isExpanded ? 0.85 : 0.3))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

// LibraryContentView - まずは固定テキストのみ
struct LibraryContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("ライブラリ")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 60)

            // Content - 固定テキストのみ
            ScrollView {
                VStack(spacing: 16) {
                    Text("テスト表示")
                        .foregroundColor(.white)
                    Text("問題なく再起動できるか確認中")
                        .foregroundColor(.white)
                }
                .padding()
            }
        }
    }
}
