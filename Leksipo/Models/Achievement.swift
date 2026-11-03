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
}

enum AchievementType: String, Codable, CaseIterable {
    case cardsCreated
    case cardsSolved
    case streak
    case dailyGoalCompleted
    case favourites
    case groupsCreated
    
    // TODO: реализовать в следующих версиях:
    // case groupPerfect
    // case groupCompleted
}
