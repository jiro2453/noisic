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
    @StateObject private var musicInfoReader = MusicInfoReader()
    @StateObject private var libraryManager = LibraryManager()

    init() {
        // Configure audio session for ambient sound playback with other apps
        AudioSessionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(musicInfoReader)
                .environmentObject(libraryManager)
        }
    }
}
