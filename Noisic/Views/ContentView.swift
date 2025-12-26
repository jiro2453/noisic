//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @State private var currentIndex = 6 // Start from middle of tripled array

    // Triple the ambient sounds for infinite scrolling effect
    private var extendedSounds: [AmbientSound] {
        AmbientSound.allCases + AmbientSound.allCases + AmbientSound.allCases
    }

    private var actualIndex: Int {
        currentIndex % AmbientSound.allCases.count
    }

    var body: some View {
        ZStack {
            // Background Video Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(extendedSounds.enumerated()), id: \.offset) { index, sound in
                    VideoPlayerView(videoName: sound.videoFileName)
                        .tag(index)
                        .id(index) // Optimize view identity for better performance
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: currentIndex) { newValue in
                // Auto-play ambient sound when swiping
                let sound = extendedSounds[newValue]
                audioManager.play(sound: sound)

                // Handle infinite loop by jumping to middle set
                DispatchQueue.main.async {
                    if newValue < AmbientSound.allCases.count {
                        // Jumped to first set, move to middle set
                        currentIndex = newValue + AmbientSound.allCases.count
                    } else if newValue >= AmbientSound.allCases.count * 2 {
                        // Jumped to third set, move to middle set
                        currentIndex = newValue - AmbientSound.allCases.count
                    }
                }
            }

            // Gradient overlay for better text visibility
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Foreground Content
            VStack(spacing: 0) {
                // Ambient Sound Icon with Navigation Arrows at Top
                VStack(spacing: 12) {
                    // Icon with Arrows
                    HStack(spacing: 20) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))

                        Image(systemName: AmbientSound.allCases[actualIndex].icon)
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .allowsHitTesting(false)

                    // Volume Control
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))

                        Slider(
                            value: Binding(
                                get: { audioManager.volume },
                                set: { audioManager.setVolume($0) }
                            ),
                            in: 0...2
                        )
                        .accentColor(.white.opacity(0.55))
                        .frame(width: 180)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .shadow(color: .black.opacity(0.5), radius: 5)
                }
                .padding(.top, 50)

                Spacer()
                    .allowsHitTesting(false)
                    .frame(maxHeight: 30)

                // Music Player Section (Upper Center)
                MusicPlayerView(musicInfo: musicInfoReader.musicInfo)
                    .environmentObject(audioManager)
                    .environmentObject(musicInfoReader)

                Spacer()
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Auto-play first sound on launch
            if !audioManager.isPlaying {
                audioManager.play(sound: AmbientSound.allCases[0])
            }
        }
    }
}

struct MusicPlayerView: View {
    let musicInfo: MusicInfo
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @State private var rotation: Double = 0

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Album Artwork as Vinyl Record (Larger)
            VStack {
                if let artwork = musicInfo.artwork {
                    VinylRecordView(artwork: artwork, isRotating: musicInfoReader.isPlaying, rotation: $rotation)
                } else {
                    VinylRecordView(artwork: nil, isRotating: musicInfoReader.isPlaying, rotation: $rotation)
                }
            }
            .allowsHitTesting(false)

            // Song Info
            VStack(spacing: 4) {
                Text(musicInfo.title ?? "Unknown Track")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)

                Text(musicInfo.artist ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            .frame(maxWidth: 300)
            .allowsHitTesting(false)

            // Music Playback Controls (Always Visible)
            VStack(spacing: 16) {
                // Seek Bar
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { musicInfoReader.currentTime },
                            set: { musicInfoReader.seek(to: $0) }
                        ),
                        in: 0...max(musicInfoReader.duration, 1)
                    )
                    .accentColor(.white.opacity(0.55))
                    .frame(maxWidth: 300)
                    .disabled(musicInfo.title == nil)

                    // Time Labels
                    HStack {
                        Text(formatTime(musicInfoReader.currentTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        Spacer()

                        Text(formatTime(musicInfoReader.duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal, 10)
                .opacity(musicInfo.title != nil ? 1.0 : 0.4)

                // Playback Control Buttons (Stylish)
                HStack(spacing: 40) {
                    // Previous Button
                    Button(action: {
                        musicInfoReader.skipToPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .disabled(musicInfo.title == nil)

                    // Play/Pause Button
                    Button(action: {
                        musicInfoReader.playPause()
                    }) {
                        Image(systemName: musicInfoReader.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                            .offset(x: musicInfoReader.isPlaying ? 0 : 2)
                    }
                    .disabled(musicInfo.title == nil)

                    // Next Button
                    Button(action: {
                        musicInfoReader.skipToNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .disabled(musicInfo.title == nil)
                }
                .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 5)
                .opacity(musicInfo.title != nil ? 1.0 : 0.4)
            }
        }
    }
}

struct VinylRecordView: View {
    let artwork: UIImage?
    let isRotating: Bool
    @Binding var rotation: Double

    var body: some View {
        ZStack {
            // Vinyl Record Disc (narrower outer ring with transparency)
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 380, height: 380)

            // Vinyl grooves (concentric circles)
            ForEach(0..<8) { index in
                Circle()
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)
                    .frame(width: CGFloat(380 - index * 18), height: CGFloat(380 - index * 18))
            }

            // Inner label area (darker)
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 310, height: 310)

            // Album artwork or placeholder (Extra Large)
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 290, height: 290)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 290, height: 290)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.4))
                    )
            }

            // Center hole
            Circle()
                .fill(Color.black)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
        }
        .drawingGroup() // Render vinyl record to offscreen buffer for better performance
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if isRotating {
                startRotation()
            }
        }
        .onChange(of: isRotating) { newValue in
            if newValue {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }

    private func startRotation() {
        // Start clean continuous rotation at constant speed
        rotation = 0
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    private func stopRotation() {
        // Stop animation at current position
        // SwiftUI will preserve the current rotation value when animation is cancelled
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AudioManager())
            .environmentObject(MusicInfoReader())
    }
}
