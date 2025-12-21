//
//  MusicInfo.swift
//  Noisic
//
//  Created on 2025-12-21
//

import UIKit

struct MusicInfo {
    let title: String?
    let artist: String?
    let artwork: UIImage?

    var isPlaying: Bool {
        title != nil || artist != nil
    }
}
