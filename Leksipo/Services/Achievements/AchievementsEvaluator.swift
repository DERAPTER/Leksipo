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
            guard !alreadyUnlocked.contains(achievement.id) else { return false }
            return isSatisfied(achievement, snapshot: snapshot)
        }
    }
    
    // MARK: - Private
    
    private static func isSatisfied(
        _ achievement: Achievement,
        snapshot: AchievementsSnapshot
    ) -> Bool {
        switch achievement.type {
        case .cardsCreated:
            return snapshot.cardsCreated >= achievement.requiredValue
        case .cardsSolved:
            return snapshot.cardsSolved >= achievement.requiredValue
        case .streak:
            return snapshot.streak >= achievement.requiredValue
        case .dailyGoalCompleted:
            return snapshot.daysGoalCompleted >= achievement.requiredValue
        case .favourites:
            return snapshot.favouritesCount >= achievement.requiredValue
        case .groupsCreated:
            return snapshot.userGroupsCount >= achievement.requiredValue
        }
    }
}
