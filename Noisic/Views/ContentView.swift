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

// 最小限のテスト用ContentView
struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text("Noisic Test")
                .foregroundColor(.white)
                .font(.largeTitle)
        }
        .onAppear {
            print("DEBUG: ContentView onAppear")
        }
    }
}
