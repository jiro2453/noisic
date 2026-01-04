//
//  NoisicApp.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

// スプラッシュ画面
struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.118, green: 0.133, blue: 0.149)
                .ignoresSafeArea()

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        }
    }
}

@main
struct NoisicApp: App {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var musicInfoReader = MusicInfoReader()
    @StateObject private var libraryManager = LibraryManager()
    @State private var showSplash = true

    init() {
        // Configure audio session for ambient sound playback with other apps
        AudioSessionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(audioManager)
                    .environmentObject(musicInfoReader)
                    .environmentObject(libraryManager)
                    .onAppear {
                        // MusicInfoReaderにLibraryManagerを設定
                        musicInfoReader.libraryManager = libraryManager
                    }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // 2秒後にスプラッシュを非表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
