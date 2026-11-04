//
//  StatsChange.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Результат операции `StatsRepository.recordSolved(...)`.
/// Содержит счётчики правильных ответов. Поля прежней цели оставлены
/// для совместимости контракта; goalJustCompleted всегда false.
struct StatsChange {
    let goalJustCompleted: Bool
    let newStreak: Int
    let newTotalSolved: Int
    let newTodaySolved: Int
    let dailyGoal: Int
}
