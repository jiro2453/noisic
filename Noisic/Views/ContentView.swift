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

                // Ambient Sounds Grid
                AmbientSoundsGrid()

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

struct AmbientSoundsGrid: View {
    @EnvironmentObject var audioManager: AudioManager

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Ambient Sounds")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(AmbientSound.allCases) { sound in
                    AmbientSoundButton(
                        sound: sound,
                        isSelected: audioManager.currentSound == sound && audioManager.isPlaying
                    ) {
                        if audioManager.currentSound == sound && audioManager.isPlaying {
                            audioManager.stop()
                        } else {
                            audioManager.play(sound: sound)
                        }
                    }
                }
            }
        }
    }
}

struct AmbientSoundButton: View {
    let sound: AmbientSound
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sound.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .black : .white)

                Text(sound.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .black : .white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
            )
        }
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
