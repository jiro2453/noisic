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

    init() {
        print("=== Noisic App Starting ===")
        // Configure audio session for ambient sound playback with other apps
        AudioSessionManager.shared.configure()
        print("=== Noisic App Initialized ===")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(musicInfoReader)
        }
    }
}
