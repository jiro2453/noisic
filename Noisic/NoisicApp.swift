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
            Color(red: 0.96, green: 0.96, blue: 0.97)
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
    @StateObject private var storeManager = StoreManager()
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
                    .environmentObject(storeManager)
                    .onAppear {
                        // MusicInfoReaderにLibraryManagerを設定
                        musicInfoReader.libraryManager = libraryManager
                        // アプリ起動時にライブラリを更新
                        libraryManager.refreshLibrary()
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
