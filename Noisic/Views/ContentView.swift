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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // Now Playing Section
                NowPlayingView(musicInfo: musicInfoReader.musicInfo)
                    .padding(.top, 40)

                Spacer()

                // Ambient Sounds Carousel
                AmbientSoundsCarousel()

                Spacer()

                // Controls Section
                ControlsView()
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
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
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }

                // Title and Artist
                VStack(spacing: 4) {
                    Text(musicInfo.title ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(musicInfo.artist ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(maxWidth: 250)
            } else {
                // No music playing state
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No Music Playing")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
            }
        }
    }
}

struct AmbientSoundsCarousel: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Ambient Sounds")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            // Swipeable Cards
            TabView(selection: $currentIndex) {
                ForEach(Array(AmbientSound.allCases.enumerated()), id: \.element.id) { index, sound in
                    AmbientSoundCard(
                        sound: sound,
                        isPlaying: audioManager.currentSound == sound && audioManager.isPlaying
                    ) {
                        if audioManager.currentSound == sound && audioManager.isPlaying {
                            audioManager.stop()
                        } else {
                            audioManager.play(sound: sound)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 280)

            // Sound Name Indicator
            Text(AmbientSound.allCases[currentIndex].displayName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct AmbientSoundCard: View {
    let sound: AmbientSound
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: sound.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                // Play/Pause Indicator
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)

                    Text(isPlaying ? "Playing" : "Tap to Play")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isPlaying ? Color.white.opacity(0.25) : Color.white.opacity(0.12),
                                isPlaying ? Color.white.opacity(0.15) : Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPlaying ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isPlaying ? Color.white.opacity(0.2) : Color.clear, radius: 10)
        }
        .padding(.horizontal, 30)
    }
}

struct ControlsView: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(spacing: 20) {
            // Volume Control
            if audioManager.isPlaying {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)

                        Slider(
                            value: Binding(
                                get: { audioManager.volume },
                                set: { audioManager.setVolume($0) }
                            ),
                            in: 0...1
                        )
                        .accentColor(.white)

                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                    }

                    // Stop Button
                    Button(action: {
                        audioManager.stop()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
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
