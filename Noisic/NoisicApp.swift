//
//  NoisicApp.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

@main
struct NoisicApp: App {
    @StateObject private var audioManager = AudioManager()
    // @StateObject private var musicInfoReader = MusicInfoReader() // 一時的に無効化
    // @StateObject private var libraryManager = LibraryManager() // 一時的に無効化

    init() {
        // Configure audio session for ambient sound playback with other apps
        AudioSessionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                // .environmentObject(musicInfoReader) // 一時的に無効化
                // .environmentObject(libraryManager) // 一時的に無効化
        }
    }
}
