//
//  Achievement.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Достижение. Не хранится в SwiftData — это статический каталог.
/// Состояние разблокировки хранится в UserSettings.
struct Achievement: Identifiable, Hashable {
    /// Стабильный строковый ID — используется как ключ в UserSettings.
    let id: String
    let titleKey: String
    let descriptionKey: String
    let icon: String
    let requiredValue: Int
    let type: AchievementType
    
    var title: String { titleKey.localized() }
    var description: String { descriptionKey.localized() }
    var isRetired: Bool { type == .streak || type == .dailyGoalCompleted }
    var isFeatured: Bool { type == .srsStreak || type == .longTermCards || type == .srsMilestone }

    var artwork: AchievementArtwork? {
        switch type {
        case .srsMilestone:
            return SRSMilestone(rawValue: id)?.artwork
        case .srsStreak:
            switch requiredValue {
            case 3: return .rhythm3
            case 7: return .rhythm7
            case 14: return .rhythm14
            case 30: return .rhythm30
            case 100: return .rhythm100
            default: return nil
            }
        default:
            return nil
        }
    }
}

enum AchievementArtwork: String, CaseIterable {
    case firstReview = "achievement-first-review"
    case allDone = "achievement-all-done"
    case weekLater = "achievement-week-later"
    case longMemory = "achievement-long-memory"
    case wordTamed = "achievement-word-tamed"
    case rhythm3 = "achievement-rhythm-3"
    case rhythm7 = "achievement-rhythm-7"
    case rhythm14 = "achievement-rhythm-14"
    case rhythm30 = "achievement-rhythm-30"
    case rhythm100 = "achievement-rhythm-100"
}

enum AchievementType: String, Codable, CaseIterable {
    case cardsCreated
    case cardsSolved
    case streak
    case dailyGoalCompleted
    case favourites
    case groupsCreated
    case srsStreak
    case longTermCards
    case srsMilestone
    
    // TODO: реализовать в следующих версиях:
    // case groupPerfect
    // case groupCompleted
}
