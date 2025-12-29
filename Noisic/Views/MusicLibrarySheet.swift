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
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(isExpanded ? 0.85 : 0.3))
            .frame(width: isExpanded ? 390 : 70,
                   height: isExpanded ? 600 : 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 0)
            .padding(.bottom, 0)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
    }
}
