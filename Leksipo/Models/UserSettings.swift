//
//  UserSettings.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

/// Singleton-модель для настроек и общей статистики.
/// Всегда один экземпляр с `id == "singleton"`.
@Model
final class UserSettings {
    @Attribute(.unique) var id: String
    
    // Ежедневная цель
    var dailyGoal: Int
    
    // Серия и общая статистика
    var streak: Int
    var totalSolved: Int
    var lastActiveDate: Date
    var dailyGoalRewarded: Bool
    
    /// Серия дней подряд, в которые разгребены все SRS-карточки.
    /// Обновляется отдельно от `streak` через `StatsRepository.markSRSCleared`.
    var srsStreak: Int = 0
    
    // Optional-поля позволяют открыть существующую базу без потери данных.
    var solveSessionsData: Data? = nil
    var legacyMigrationCompleted: Bool? = nil

    // nil в старой базе означает исходную пару английский → русский.
    var learningLanguageCode: String? = nil
    var translationLanguageCode: String? = nil

    var languagePair: StudyLanguagePair {
        get {
            StudyLanguagePair(
                learning: learningLanguageCode.flatMap { StudyLanguage(code: $0) } ?? .english,
                translation: translationLanguageCode.flatMap { StudyLanguage(code: $0) } ?? .russian
            )
        }
        set {
            learningLanguageCode = newValue.learning.code
            translationLanguageCode = newValue.translation.code
        }
    }

    // Достижения
    var unlockedAchievementIDs: [String]
    var achievementUnlockDates: [String: Date]
    
    init() {
        self.id = "singleton"
        self.dailyGoal = 20
        self.streak = 0
        self.totalSolved = 0
        self.lastActiveDate = .now
        self.dailyGoalRewarded = false
        self.srsStreak = 0
        self.unlockedAchievementIDs = []
        self.achievementUnlockDates = [:]
    }
    
    // MARK: - Achievement helpers
    
    func isUnlocked(_ achievementID: String) -> Bool {
        unlockedAchievementIDs.contains(achievementID)
    }
    
    func unlock(_ achievementID: String, on date: Date = .now) {
        guard !unlockedAchievementIDs.contains(achievementID) else { return }
        unlockedAchievementIDs.append(achievementID)
        achievementUnlockDates[achievementID] = date
    }
}
