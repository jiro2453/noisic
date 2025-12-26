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

    var videoFileName: String {
        return rawValue
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

    // Volume multiplier (bonfire is baseline at 1.0)
    var volumeMultiplier: Float {
        switch self {
        case .nightRain: return 1.0
        case .nature: return 1.0
        case .drive: return 1.0
        case .river: return 1.0
        case .ocean: return 1.0
        case .bonfire: return 1.0  // Baseline
        }
    }
}
