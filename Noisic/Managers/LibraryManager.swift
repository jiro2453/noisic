//
//  LibraryManager.swift
//  Noisic
//
//  Created on 2025-12-27
//

import MediaPlayer
import Combine

struct LibraryAlbum: Identifiable {
    let id: UInt64
    let title: String?
    let artist: String?
    let artwork: UIImage?
    let collection: MPMediaItemCollection
}

class LibraryManager: ObservableObject {
    @Published var recentlyAdded: [LibraryAlbum] = []
    @Published var recentlyPlayed: [LibraryAlbum] = []
    @Published var combinedAlbums: [LibraryAlbum] = []
    @Published var allAlbums: [LibraryAlbum] = []
    @Published var isAuthorized = false

    private var hasCheckedAuthorization = false

    init() {
        // Don't check authorization in init to avoid blocking
    }

    func checkAuthorization() {
        guard !hasCheckedAuthorization else { return }
        hasCheckedAuthorization = true

        DispatchQueue.main.async { [weak self] in
            let status = MPMediaLibrary.authorizationStatus()

            switch status {
            case .authorized:
                self?.isAuthorized = true
                self?.loadLibrary()
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
                self?.isAuthorized = false
            }
        }
    }

    func loadLibrary() {
        loadRecentlyAdded()
        loadRecentlyPlayed()
        loadAllAlbums()
    }

    private func loadRecentlyAdded() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let query = MPMediaQuery.albums()

            guard let collections = query.collections else {
                DispatchQueue.main.async {
                    self?.recentlyAdded = []
                    self?.updateCombinedAlbums()
                }
                return
            }

            // Sort by date added (most recent first)
            let sortedCollections = collections.sorted { collection1, collection2 in
                let date1 = collection1.items.first?.dateAdded ?? Date.distantPast
                let date2 = collection2.items.first?.dateAdded ?? Date.distantPast
                return date1 > date2
            }

            // Take first 50 albums
            let recentAlbums = Array(sortedCollections.prefix(50))

            let albums = recentAlbums.compactMap { collection -> LibraryAlbum? in
                guard let representativeItem = collection.representativeItem else { return nil }

                return LibraryAlbum(
                    id: collection.persistentID,
                    title: representativeItem.albumTitle,
                    artist: representativeItem.albumArtist ?? representativeItem.artist,
                    artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                    collection: collection
                )
            }

            DispatchQueue.main.async {
                self?.recentlyAdded = albums
                self?.updateCombinedAlbums()
            }
        }
    }

    private func loadRecentlyPlayed() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let query = MPMediaQuery.albums()

            guard let collections = query.collections else {
                DispatchQueue.main.async {
                    self?.recentlyPlayed = []
                    self?.updateCombinedAlbums()
                }
                return
            }

            // Sort by last played date (most recent first)
            let sortedCollections = collections.sorted { collection1, collection2 in
                let date1 = collection1.items.first?.lastPlayedDate ?? Date.distantPast
                let date2 = collection2.items.first?.lastPlayedDate ?? Date.distantPast
                return date1 > date2
            }.filter { collection in
                // Only include albums that have been played
                collection.items.first?.lastPlayedDate != nil
            }

            // Take first 30 recently played albums
            let recentAlbums = Array(sortedCollections.prefix(30))

            let albums = recentAlbums.compactMap { collection -> LibraryAlbum? in
                guard let representativeItem = collection.representativeItem else { return nil }

                return LibraryAlbum(
                    id: collection.persistentID,
                    title: representativeItem.albumTitle,
                    artist: representativeItem.albumArtist ?? representativeItem.artist,
                    artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                    collection: collection
                )
            }

            DispatchQueue.main.async {
                self?.recentlyPlayed = albums
                self?.updateCombinedAlbums()
            }
        }
    }

    private func updateCombinedAlbums() {
        // Combine recently played (priority) + recently added, removing duplicates
        var seen = Set<UInt64>()
        var combined: [LibraryAlbum] = []

        // Add recently played first
        for album in recentlyPlayed {
            if !seen.contains(album.id) {
                seen.insert(album.id)
                combined.append(album)
            }
        }

        // Then add recently added
        for album in recentlyAdded {
            if !seen.contains(album.id) {
                seen.insert(album.id)
                combined.append(album)
            }
        }

        // Limit to 50
        combinedAlbums = Array(combined.prefix(50))
    }

    private func loadAllAlbums() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let query = MPMediaQuery.albums()

            guard let collections = query.collections else {
                DispatchQueue.main.async {
                    self?.allAlbums = []
                }
                return
            }

            // Take first 50 albums for performance
            let limitedCollections = Array(collections.prefix(50))

            let albums = limitedCollections.compactMap { collection -> LibraryAlbum? in
                guard let representativeItem = collection.representativeItem else { return nil }

                return LibraryAlbum(
                    id: collection.persistentID,
                    title: representativeItem.albumTitle,
                    artist: representativeItem.albumArtist ?? representativeItem.artist,
                    artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                    collection: collection
                )
            }

            DispatchQueue.main.async {
                self?.allAlbums = albums
            }
        }
    }

    func playAlbum(_ album: LibraryAlbum) {
        let player = MPMusicPlayerController.systemMusicPlayer
        player.setQueue(with: album.collection)
        player.play()
    }
}
