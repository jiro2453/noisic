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
    private var currentPlayingAlbumId: UInt64?

    init() {
        // 再生中の曲が変わった時の通知を受け取る
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil
        )
        MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
    }

    @objc private func nowPlayingItemChanged() {
        // 現在再生中のアルバムを最近再生の先頭に追加
        updateCurrentPlayingAlbum()
    }

    /// 現在再生中のアルバムを最近再生リストの先頭に追加
    func updateCurrentPlayingAlbum() {
        guard let nowPlaying = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem else {
            return
        }

        let albumId = nowPlaying.albumPersistentID

        // 同じアルバムなら更新不要
        if albumId == currentPlayingAlbumId {
            return
        }
        currentPlayingAlbumId = albumId

        // アルバム情報を取得
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let query = MPMediaQuery.albums()
            query.addFilterPredicate(MPMediaPropertyPredicate(
                value: albumId,
                forProperty: MPMediaItemPropertyAlbumPersistentID
            ))

            guard let collection = query.collections?.first,
                  let representativeItem = collection.representativeItem else {
                return
            }

            let newAlbum = LibraryAlbum(
                id: collection.persistentID,
                title: representativeItem.albumTitle,
                artist: representativeItem.albumArtist ?? representativeItem.artist,
                artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                collection: collection
            )

            DispatchQueue.main.async {
                guard let self = self else { return }

                // 既存のリストから同じアルバムを削除
                var updated = self.recentlyPlayed.filter { $0.id != newAlbum.id }

                // 先頭に追加
                updated.insert(newAlbum, at: 0)

                // 30件に制限
                if updated.count > 30 {
                    updated = Array(updated.prefix(30))
                }

                self.recentlyPlayed = updated
                self.updateCombinedAlbums()
            }
        }
    }

    func checkAuthorization() {
        let status = MPMediaLibrary.authorizationStatus()

        switch status {
        case .authorized:
            isAuthorized = true
            if !hasCheckedAuthorization {
                hasCheckedAuthorization = true
                loadLibrary()
            }
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.isAuthorized = (newStatus == .authorized)
                    self?.hasCheckedAuthorization = true
                    if newStatus == .authorized {
                        self?.loadLibrary()
                    }
                }
            }
        default:
            isAuthorized = false
            hasCheckedAuthorization = true
        }
    }

    /// ライブラリを強制的に更新
    func refreshLibrary() {
        let status = MPMediaLibrary.authorizationStatus()
        if status == .authorized {
            isAuthorized = true
            loadLibrary()
        } else if !hasCheckedAuthorization {
            checkAuthorization()
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
        // 現在再生中のアルバムIDを先に取得
        let currentAlbumId = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem?.albumPersistentID

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let query = MPMediaQuery.albums()

            guard let collections = query.collections else {
                DispatchQueue.main.async {
                    self?.recentlyPlayed = []
                    self?.updateCombinedAlbums()
                }
                return
            }

            // Helper function to get the most recent play date from all items in an album
            func mostRecentPlayDate(for collection: MPMediaItemCollection) -> Date? {
                collection.items.compactMap { $0.lastPlayedDate }.max()
            }

            // Sort by last played date (most recent first) - use max date from all tracks
            let sortedCollections = collections.filter { collection in
                // Only include albums that have been played
                mostRecentPlayDate(for: collection) != nil
            }.sorted { collection1, collection2 in
                let date1 = mostRecentPlayDate(for: collection1) ?? Date.distantPast
                let date2 = mostRecentPlayDate(for: collection2) ?? Date.distantPast
                return date1 > date2
            }

            // Take first 30 recently played albums
            let recentAlbums = Array(sortedCollections.prefix(30))

            var albums = recentAlbums.compactMap { collection -> LibraryAlbum? in
                guard let representativeItem = collection.representativeItem else { return nil }

                return LibraryAlbum(
                    id: collection.persistentID,
                    title: representativeItem.albumTitle,
                    artist: representativeItem.albumArtist ?? representativeItem.artist,
                    artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                    collection: collection
                )
            }

            // 現在再生中のアルバムを先頭に移動
            if let currentId = currentAlbumId {
                // 現在再生中のアルバムがリストにあれば先頭に移動
                if let index = albums.firstIndex(where: { $0.id == currentId }) {
                    let currentAlbum = albums.remove(at: index)
                    albums.insert(currentAlbum, at: 0)
                } else {
                    // リストにない場合は新たに取得して先頭に追加
                    let currentQuery = MPMediaQuery.albums()
                    currentQuery.addFilterPredicate(MPMediaPropertyPredicate(
                        value: currentId,
                        forProperty: MPMediaItemPropertyAlbumPersistentID
                    ))
                    if let collection = currentQuery.collections?.first,
                       let representativeItem = collection.representativeItem {
                        let currentAlbum = LibraryAlbum(
                            id: collection.persistentID,
                            title: representativeItem.albumTitle,
                            artist: representativeItem.albumArtist ?? representativeItem.artist,
                            artwork: representativeItem.artwork?.image(at: CGSize(width: 200, height: 200)),
                            collection: collection
                        )
                        albums.insert(currentAlbum, at: 0)
                        // 30件に制限
                        if albums.count > 30 {
                            albums = Array(albums.prefix(30))
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self?.recentlyPlayed = albums
                self?.currentPlayingAlbumId = currentAlbumId
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

        // Limit to 49
        combinedAlbums = Array(combined.prefix(49))
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
