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
                VStack(spacing: 8) {
                    Text(AmbientSound.allCases[currentIndex].displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)

                    Text("Swipe to change")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .shadow(color: .black.opacity(0.5), radius: 5)
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

    var body: some View {
        VStack(spacing: 24) {
            // Album Artwork
            if musicInfo.isPlaying {
                if let artwork = musicInfo.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.6), radius: 30)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 70))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .shadow(color: .black.opacity(0.6), radius: 30)
                }
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.4))

                            Text("No Music Playing")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
                    .shadow(color: .black.opacity(0.6), radius: 30)
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

            // Ambient Sound Controls
            if audioManager.isPlaying {
                VStack(spacing: 16) {
                    // Volume Control
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))

                            Text("Ambient Volume")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()
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
                }
                .frame(maxWidth: 280)
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
