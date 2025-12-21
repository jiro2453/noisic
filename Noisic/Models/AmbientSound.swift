//
//  AmbientSound.swift
//  Noisic
//
//  Created on 2025-12-21
//

import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case nightRain = "night_rain"
    case nature = "nature"
    case drive = "drive"
    case river = "river"
    case ocean = "ocean"
    case bonfire = "bonfire"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nightRain: return "Night Rain"
        case .nature: return "Nature"
        case .drive: return "Drive"
        case .river: return "River"
        case .ocean: return "Ocean"
        case .bonfire: return "Bonfire"
        }
    }

    var fileName: String {
        return "\(rawValue).mp3"
    }

    var icon: String {
        switch self {
        case .nightRain: return "cloud.rain.fill"
        case .nature: return "leaf.fill"
        case .drive: return "car.fill"
        case .river: return "drop.fill"
        case .ocean: return "water.waves"
        case .bonfire: return "flame.fill"
        }
    }
}
