//
//  AmbientSound.swift
//  Noisic
//
//  Created on 2025-12-21
//

import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case bonfire = "bonfire"
    case nightRain = "night_rain"
    case nature = "nature"
    case ocean = "ocean"
    case drive = "drive"
    case river = "river"

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
        case .nightRain: return 60.0
        case .nature: return 12.0
        case .drive: return 12.0
        case .river: return 20.0
        case .ocean: return 10.0
        case .bonfire: return 0.7
        }
    }

    // プレミアムコンテンツかどうか（ocean, drive, riverは課金が必要）
    var isPremium: Bool {
        switch self {
        case .ocean, .drive, .river:
            return true
        case .bonfire, .nightRain, .nature:
            return false
        }
    }

    // 各サウンドのプロダクトID
    var productId: String? {
        switch self {
        case .ocean:
            return "com.noisic.sound.ocean"
        case .drive:
            return "com.noisic.sound.drive"
        case .river:
            return "com.noisic.sound.river"
        default:
            return nil
        }
    }
}
