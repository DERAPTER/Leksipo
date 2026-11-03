//
//  AchievementsSnapshot.swift
//  Leksipo
//
//  Created by Егор Халиков on 26.09.2026.
//

import Foundation

/// Снимок текущего состояния для проверки достижений.
/// Формируется сервисом и передаётся в evaluator — так evaluator остаётся чистой функцией.
struct AchievementsSnapshot {
    let cardsCreated: Int
    let cardsSolved: Int
    let streak: Int
    let daysGoalCompleted: Int
    let favouritesCount: Int
    let userGroupsCount: Int
}
