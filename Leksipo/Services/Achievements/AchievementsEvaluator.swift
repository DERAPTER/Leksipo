//
//  AchievementsEvaluator.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Чистая логика проверки достижений.
/// Не знает ни о SwiftData, ни о репозиториях, ни о UI — только о снимке и каталоге.
enum AchievementsEvaluator {
    
    /// Возвращает список достижений, условия которых выполнены,
    /// но которые ещё не были разблокированы.
    static func newlyUnlocked(
        snapshot: AchievementsSnapshot,
        alreadyUnlocked: Set<String>
    ) -> [Achievement] {
        AchievementsCatalog.all.filter { achievement in
            guard !achievement.isRetired, !alreadyUnlocked.contains(achievement.id) else { return false }
            return currentValue(for: achievement, snapshot: snapshot) >= achievement.requiredValue
        }
    }
    
    static func currentValue(for achievement: Achievement, snapshot: AchievementsSnapshot) -> Int {
        switch achievement.type {
        case .cardsCreated: return snapshot.cardsCreated
        case .cardsSolved: return snapshot.cardsSolved
        case .streak: return snapshot.streak
        case .dailyGoalCompleted: return snapshot.daysGoalCompleted
        case .favourites: return snapshot.favouritesCount
        case .groupsCreated: return snapshot.userGroupsCount
        case .srsStreak: return snapshot.srsStreak
        case .longTermCards: return snapshot.longTermCards
        case .srsMilestone:
            guard let milestone = SRSMilestone(rawValue: achievement.id) else { return 0 }
            return snapshot.srsMilestonesRaw & milestone.mask != 0 ? 1 : 0
        }
    }
}
