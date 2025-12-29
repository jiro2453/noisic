//
//  MusicLibrarySheet.swift
//  Noisic
//
//  Created on 2025-12-27
//

import SwiftUI

struct MusicLibrarySheet: View {
    var body: some View {
        // 最もシンプルな実装：右下に固定サイズの四角形を表示するだけ
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 70, height: 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 0)
            .padding(.bottom, 0)
    }
}
