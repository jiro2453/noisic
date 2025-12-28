//
//  ContentView.swift
//  Noisic
//
//  Created on 2025-12-21
//

import SwiftUI

// Custom Slider with full-width track (Float version)
struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbOffset = percentage * geometry.size.width

            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: trackHeight)
                    .cornerRadius(trackHeight / 2)

                // Active track (from left edge to thumb center)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: thumbOffset, height: trackHeight)
                    .cornerRadius(trackHeight / 2)

                // Thumb
                Circle()
                    .fill(Color.gray)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: thumbOffset - thumbSize / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newPercentage = max(0, min(1, gesture.location.x / geometry.size.width))
                        let newValue = Float(newPercentage) * (range.upperBound - range.lowerBound) + range.lowerBound
                        value = newValue
                    }
            )
        }
        .frame(height: 44)
    }
}

// Custom Slider with full-width track (Double version)
struct CustomSliderDouble: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 20
    var isDisabled: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbOffset = percentage * geometry.size.width

            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: trackHeight)
                    .cornerRadius(trackHeight / 2)

                // Active track (from left edge to thumb center)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: thumbOffset, height: trackHeight)
                    .cornerRadius(trackHeight / 2)

                // Thumb
                Circle()
                    .fill(Color.gray)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: thumbOffset - thumbSize / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDisabled {
                            let newPercentage = max(0, min(1, gesture.location.x / geometry.size.width))
                            let newValue = Double(newPercentage) * (range.upperBound - range.lowerBound) + range.lowerBound
                            value = newValue
                        }
                    }
            )
        }
        .frame(height: 44)
    }
}

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var musicInfoReader: MusicInfoReader
    @EnvironmentObject var libraryManager: LibraryManager
    @State private var currentIndex = 11 // Start from bonfire in middle of tripled array (6+5)

    // Music Library Sheet
    @State private var sheetOffset: CGFloat = 1000 // Will be set in onAppear
    @State private var isLibraryExpanded = false

    // Triple the ambient sounds for infinite scrolling effect
    private var extendedSounds: [AmbientSound] {
        AmbientSound.allCases + AmbientSound.allCases + AmbientSound.allCases
    }

    private var actualIndex: Int {
        currentIndex % AmbientSound.allCases.count
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Video Carousel
                TabView(selection: $currentIndex) {
                    ForEach(Array(extendedSounds.enumerated()), id: \.offset) { index, sound in
                        VideoPlayerView(videoName: sound.videoFileName)
                            .tag(index)
                            .id(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .onChange(of: currentIndex) { newValue in
                // Auto-play ambient sound when swiping
                let sound = extendedSounds[newValue]
                audioManager.play(sound: sound)

                // Handle infinite loop by jumping to middle set
                // Only jump when at the edges (first 2 or last 2 items)
                let count = AmbientSound.allCases.count
                if newValue <= 1 {
                    // At start of first set, jump to same position in middle set
                    DispatchQueue.main.async {
                        currentIndex = newValue + count
                    }
                } else if newValue >= (count * 3) - 2 {
                    // At end of third set, jump to same position in middle set
                    DispatchQueue.main.async {
                        currentIndex = newValue - count
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
                            .foregroundColor(.white)
                            .opacity(0.4)

                        Image(systemName: AmbientSound.allCases[actualIndex].icon)
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .opacity(0.55)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(0.4)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .allowsHitTesting(false)

                    // Volume Control
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .opacity(0.5)
                            .allowsHitTesting(false)

                        CustomSlider(
                            value: Binding(
                                get: { audioManager.volume },
                                set: { audioManager.setVolume($0) }
                            ),
                            range: 1...4
                        )
                        .frame(width: 180)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .opacity(0.5)
                            .allowsHitTesting(false)
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

            // Music Library Sheet
            MusicLibrarySheet(
                offset: $sheetOffset,
                isExpanded: $isLibraryExpanded,
                maxHeight: geometry.size.height * 0.7
            )
            .zIndex(100)
            }
            .onAppear {
                // Auto-play bonfire on launch
                if !audioManager.isPlaying {
                    audioManager.play(sound: .bonfire)
                }
                // Initialize sheet offset on first appear
                if sheetOffset == 1000 {
                    // Position at bottom of screen, showing only the handle
                    sheetOffset = geometry.size.height - 80
                }
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
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)

                Text(musicInfo.artist ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            .frame(maxWidth: 300)
            .opacity(0.55)
            .allowsHitTesting(false)

            // Music Playback Controls (Always Visible)
            VStack(spacing: 16) {
                // Seek Bar
                VStack(spacing: 6) {
                    CustomSliderDouble(
                        value: Binding(
                            get: { musicInfoReader.currentTime },
                            set: { musicInfoReader.seek(to: $0) }
                        ),
                        range: 0...max(musicInfoReader.duration, 1),
                        isDisabled: musicInfo.title == nil
                    )
                    .frame(maxWidth: 300)

                    // Time Labels
                    HStack {
                        Text(formatTime(musicInfoReader.currentTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Text(formatTime(musicInfoReader.duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: 300)
                    .opacity(musicInfo.title != nil ? 0.5 : 0.2)
                    .allowsHitTesting(false)
                }
                .padding(.horizontal, 10)

                // Playback Control Buttons (Stylish)
                HStack(spacing: 40) {
                    // Previous Button
                    Button(action: {
                        musicInfoReader.skipToPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .contentShape(Rectangle())
                    }
                    .disabled(musicInfo.title == nil)

                    // Play/Pause Button
                    Button(action: {
                        musicInfoReader.playPause()
                    }) {
                        Image(systemName: musicInfoReader.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: musicInfoReader.isPlaying ? 0 : 2)
                            .frame(width: 60, height: 60)
                            .contentShape(Rectangle())
                    }
                    .disabled(musicInfo.title == nil)

                    // Next Button
                    Button(action: {
                        musicInfoReader.skipToNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .contentShape(Rectangle())
                    }
                    .disabled(musicInfo.title == nil)
                }
                .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 5)
                .opacity(musicInfo.title != nil ? 0.55 : 0.2)
            }
        }
    }
}

struct VinylRecordView: View {
    let artwork: UIImage?
    let isRotating: Bool
    @Binding var rotation: Double
    @State private var rotationTimer: Timer?

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
        .onDisappear {
            rotationTimer?.invalidate()
            rotationTimer = nil
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
        // Stop any existing timer
        rotationTimer?.invalidate()

        // 12秒で360度回転 = 1秒で30度 = 1/60秒で0.5度
        let degreesPerFrame = 30.0 / 60.0

        rotationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [self] _ in
            rotation += degreesPerFrame
            // Keep rotation within reasonable bounds to avoid overflow
            if rotation >= 360 {
                rotation -= 360
            }
        }
    }

    private func stopRotation() {
        // Stop timer and preserve current rotation angle
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AudioManager())
            .environmentObject(MusicInfoReader())
            .environmentObject(LibraryManager())
    }
}
