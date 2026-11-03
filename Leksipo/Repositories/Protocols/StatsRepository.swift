//
//  StatsRepository.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
protocol StatsRepository {
    // Settings
    func settings() throws -> UserSettings
    func updateStudyLanguages(_ pair: StudyLanguagePair) throws
    func unlockAchievements(_ ids: [String], on date: Date) throws
    func updateDailyGoal(_ goal: Int) throws
    
    // Recording
    func recordSolved(on date: Date) throws -> StatsChange
    
    /// Помечает день как «SRS разгребён» и обновляет `srsStreak`.
    /// Идемпотентно: повторный вызов в тот же день ничего не меняет.
    func markSRSCleared(on date: Date) throws
    
    func updateSRSStatus(on date: Date, hasDueCards: Bool, nextReviewDate: Date?) throws
    func currentStreak(on date: Date) throws -> Int
    func currentSRSStreak(on date: Date) throws -> Int

    // Activity
    func activity(for date: Date) throws -> DailyStat?
    /// Отрицательный monthsBack запрашивает всю сохранённую историю.
    func activityHistory(monthsBack: Int) throws -> [DailyStat]
    func isDateActive(_ date: Date) throws -> Bool
    func totalDaysGoalCompleted() throws -> Int
    
    // Reset
    func resetAllStats() throws
}
