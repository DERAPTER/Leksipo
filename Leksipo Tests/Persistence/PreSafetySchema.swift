import Foundation
import SwiftData

// Схема UserSettings до переноса очередей в SwiftData.
enum PreSafetySchema {
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
}


extension PreSafetySchema {
    /// Форма DailyStat до введения дневного лимита и истории SRS-назначений.
    @Model
    final class DailyStat {
        @Attribute(.unique) var dateKey: String
        var date: Date
        var solvedCount: Int
        var goalCompleted: Bool
        var srsCleared: Bool = false

        init(date: Date, dateKey: String, solvedCount: Int) {
            self.date = Calendar.current.startOfDay(for: date)
            self.dateKey = dateKey
            self.solvedCount = solvedCount
            self.goalCompleted = false
        }
    }
}
