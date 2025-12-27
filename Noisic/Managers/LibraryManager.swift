//
//  LibraryManager.swift
//  Noisic
//
//  Created on 2025-12-27
//

import MediaPlayer
import Combine

struct LibraryTrack: Identifiable {
    let id: UInt64
    let title: String
    let artist: String?
    let artwork: UIImage?
    let mediaItem: MPMediaItem
}

class LibraryManager: ObservableObject {
    @Published var recentlyAdded: [LibraryTrack] = []
    @Published var allSongs: [LibraryTrack] = []
    @Published var isAuthorized = false

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        let status = MPMediaLibrary.authorizationStatus()

        switch status {
        case .authorized:
            isAuthorized = true
            loadLibrary()
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.isAuthorized = (newStatus == .authorized)
                    if newStatus == .authorized {
                        self?.loadLibrary()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }

    func loadLibrary() {
        loadRecentlyAdded()
        loadAllSongs()
    }

    private func loadRecentlyAdded() {
        let query = MPMediaQuery.songs()

        guard let items = query.items else {
            recentlyAdded = []
            return
        }

        // Sort by date added (most recent first)
        let sortedItems = items.sorted { item1, item2 in
            let date1 = item1.dateAdded
            let date2 = item2.dateAdded
            return date1 > date2
        }

        // Take first 50
        let recentItems = Array(sortedItems.prefix(50))

        recentlyAdded = recentItems.compactMap { item -> LibraryTrack? in
            guard let title = item.title else { return nil }

            return LibraryTrack(
                id: item.persistentID,
                title: title,
                artist: item.artist,
                artwork: item.artwork?.image(at: CGSize(width: 200, height: 200)),
                mediaItem: item
            )
        }
    }

    private func loadAllSongs() {
        let query = MPMediaQuery.songs()

        guard let items = query.items else {
            allSongs = []
            return
        }

        // Take first 100 for performance
        let limitedItems = Array(items.prefix(100))

        allSongs = limitedItems.compactMap { item -> LibraryTrack? in
            guard let title = item.title else { return nil }

            return LibraryTrack(
                id: item.persistentID,
                title: title,
                artist: item.artist,
                artwork: item.artwork?.image(at: CGSize(width: 200, height: 200)),
                mediaItem: item
            )
        }
    }

    func playTrack(_ track: LibraryTrack) {
        let player = MPMusicPlayerController.systemMusicPlayer
        let collection = MPMediaItemCollection(items: [track.mediaItem])
        player.setQueue(with: collection)
        player.play()
    }
}
