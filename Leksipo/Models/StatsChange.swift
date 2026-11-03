//
//  StatsChange.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Результат операции `StatsRepository.recordSolved(...)`.
/// ViewModel использует это, чтобы обновить UI и проверить достижения.
struct StatsChange {
    let goalJustCompleted: Bool
    let newStreak: Int
    let newTotalSolved: Int
    let newTodaySolved: Int
    let dailyGoal: Int
}
