//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

// Custom Slider with full-width track (Float version)
struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 20

    var body: some View {
        let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let thumbOffset = percentage * 180 // Fixed width

        ZStack(alignment: .leading) {
            // Background track
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 180, height: trackHeight)
                .cornerRadius(trackHeight / 2)

            // Active track
            Rectangle()
                .fill(Color.white)
                .frame(width: thumbOffset, height: trackHeight)
                .cornerRadius(trackHeight / 2)

            // Thumb
            Circle()
                .fill(Color.gray)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: thumbOffset - thumbSize / 2)
        }
        .frame(width: 180, height: 44)
    }
}

// テスト1: AmbientSoundへのアクセスのみ
struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var currentIndex = 5  // 11ではなく5に変更（安全な範囲内）

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                Text("Count: \(AmbientSound.allCases.count)")
                    .foregroundColor(.white)

                Text("Index: \(currentIndex)")
                    .foregroundColor(.white)

                if currentIndex < AmbientSound.allCases.count {
                    Text("Sound: \(AmbientSound.allCases[currentIndex].displayName)")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            print("DEBUG: ContentView onAppear")
            print("DEBUG: AmbientSound.allCases.count = \(AmbientSound.allCases.count)")
        }
    }
}
