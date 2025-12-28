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
    @Published var allAlbums: [LibraryAlbum] = []
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
        loadAllAlbums()
    }

    private func loadRecentlyAdded() {
        let query = MPMediaQuery.albums()

        guard let collections = query.collections else {
            recentlyAdded = []
            return
        }

        // Sort by date added (most recent first)
        let sortedCollections = collections.sorted { collection1, collection2 in
            let date1 = collection1.items.first?.dateAdded ?? Date.distantPast
            let date2 = collection2.items.first?.dateAdded ?? Date.distantPast
            return date1 > date2
        }

        // Take first 30 albums
        let recentAlbums = Array(sortedCollections.prefix(30))

        recentlyAdded = recentAlbums.compactMap { collection -> LibraryAlbum? in
            guard let representativeItem = collection.representativeItem else { return nil }

            return LibraryAlbum(
                id: collection.persistentID,
                title: representativeItem.albumTitle,
                artist: representativeItem.albumArtist ?? representativeItem.artist,
                artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                collection: collection
            )
        }
    }

    private func loadAllAlbums() {
        let query = MPMediaQuery.albums()

        guard let collections = query.collections else {
            allAlbums = []
            return
        }

        // Take first 50 albums for performance
        let limitedCollections = Array(collections.prefix(50))

        allAlbums = limitedCollections.compactMap { collection -> LibraryAlbum? in
            guard let representativeItem = collection.representativeItem else { return nil }

            return LibraryAlbum(
                id: collection.persistentID,
                title: representativeItem.albumTitle,
                artist: representativeItem.albumArtist ?? representativeItem.artist,
                artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                collection: collection
            )
        }
    }

    func playAlbum(_ album: LibraryAlbum) {
        let player = MPMusicPlayerController.systemMusicPlayer
        player.setQueue(with: album.collection)
        player.play()
    }
}
