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

            // Foreground Content
            VStack(spacing: 30) {
                // Now Playing Section
                NowPlayingView(musicInfo: musicInfoReader.musicInfo)
                    .padding(.top, 40)

                Spacer()

                // Ambient Sound Name
                VStack(spacing: 8) {
                    Text(AmbientSound.allCases[currentIndex].displayName)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)

                    Text("Swipe to change")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }

                Spacer()

                // Controls Section
                ControlsView()
                    .padding(.bottom, 40)
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

struct NowPlayingView: View {
    let musicInfo: MusicInfo

    var body: some View {
        VStack(spacing: 12) {
            if musicInfo.isPlaying {
                // Artwork
                if let artwork = musicInfo.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.5), radius: 20)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .shadow(color: .black.opacity(0.5), radius: 20)
                }

                // Title and Artist
                VStack(spacing: 4) {
                    Text(musicInfo.title ?? "Unknown")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 5)

                    Text(musicInfo.artist ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }
                .frame(maxWidth: 250)
            } else {
                // No music playing state
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.5))
                        .shadow(color: .black.opacity(0.5), radius: 5)

                    Text("No Music Playing")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }
                .frame(height: 180)
            }
        }
    }
}

struct ControlsView: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(spacing: 16) {
            // Volume Control
            if audioManager.isPlaying {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.5), radius: 5)

                        Slider(
                            value: Binding(
                                get: { audioManager.volume },
                                set: { audioManager.setVolume($0) }
                            ),
                            in: 0...1
                        )
                        .accentColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3)

                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.5), radius: 5)
                    }
                    .padding(.horizontal, 4)

                    // Stop Button
                    Button(action: {
                        audioManager.stop()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Ambient Sound")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red.opacity(0.7))
                                .shadow(color: .black.opacity(0.5), radius: 10)
                        )
                    }
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
