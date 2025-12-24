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
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            // Background Video Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(AmbientSound.allCases.enumerated()), id: \.element.id) { index, sound in
                    VideoPlayerView(videoName: sound.videoFileName)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: currentIndex) { newValue in
                // Auto-play ambient sound when swiping
                let sound = AmbientSound.allCases[newValue]
                audioManager.play(sound: sound)
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
                // Ambient Sound Name at Top
                VStack(spacing: 12) {
                    // Icon
                    Image(systemName: AmbientSound.allCases[currentIndex].icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)

                    // Sound Name with Swipe Indicators
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        Text(AmbientSound.allCases[currentIndex].displayName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)
                }
                .padding(.top, 60)
                .allowsHitTesting(false)

                Spacer()
                    .allowsHitTesting(false)

                // Music Player Section (Center to Bottom)
                MusicPlayerView(musicInfo: musicInfoReader.musicInfo)
                    .environmentObject(audioManager)
                    .padding(.bottom, 50)
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
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Album Artwork as Vinyl Record
            if musicInfo.isPlaying {
                if let artwork = musicInfo.artwork {
                    VinylRecordView(artwork: artwork, isRotating: true, rotation: $rotation)
                } else {
                    VinylRecordView(artwork: nil, isRotating: true, rotation: $rotation)
                }
            } else {
                VinylRecordView(artwork: nil, isRotating: false, rotation: $rotation)
            }

            // Song Info
            VStack(spacing: 6) {
                Text(musicInfo.title ?? "Unknown Track")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)

                Text(musicInfo.artist ?? "Unknown Artist")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            .frame(maxWidth: 280)

            // Ambient Sound Volume Control (Always visible)
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Ambient Volume")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("\(Int(audioManager.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))

                    Slider(
                        value: Binding(
                            get: { audioManager.volume },
                            set: { audioManager.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .accentColor(.white)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .shadow(color: .black.opacity(0.3), radius: 10)
            )
            .frame(maxWidth: 280)

            // Ambient Sound Controls
            if audioManager.isPlaying {
                // Stop Button
                Button(action: {
                    audioManager.stop()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 18))
                        Text("Stop Ambient")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.7))
                            .shadow(color: .black.opacity(0.4), radius: 10)
                    )
                }
                .frame(maxWidth: 280)
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
            // Vinyl Record Disc
            Circle()
                .fill(Color.black)
                .frame(width: 300, height: 300)
                .shadow(color: .black.opacity(0.8), radius: 40)

            // Vinyl grooves (concentric circles)
            ForEach(0..<8) { index in
                Circle()
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)
                    .frame(width: CGFloat(300 - index * 15), height: CGFloat(300 - index * 15))
            }

            // Inner label area (darker)
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 220, height: 220)

            // Album artwork or placeholder
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.4))
                    )
            }

            // Center hole
            Circle()
                .fill(Color.black)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if isRotating {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
        .onChange(of: isRotating) { newValue in
            if newValue {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                withAnimation(.linear(duration: 0.5)) {
                    rotation = 0
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AudioManager())
            .environmentObject(MusicInfoReader())
    }
}
