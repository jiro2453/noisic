//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Noisic")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)

                Text("起動テスト")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
