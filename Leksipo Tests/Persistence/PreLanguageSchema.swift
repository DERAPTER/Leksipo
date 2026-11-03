import Foundation
import SwiftData
@testable import English_Words

// Снимок моделей до добавления языков: проверяет обновление существующего store.
enum PreLanguageSchema {
    @Model
    final class Card {
        @Attribute(.unique) var id: UUID
        var originWord: String
        var translatedWord: String
        var originDescription: String = ""
        var translatedDescription: String = ""
        var isFavourite: Bool
        var dateAdded: Date
        var correctCount: Int
        var wrongCount: Int
        
        // MARK: - SRS (SM-2)
        
        /// Коэффициент лёгкости. По умолчанию 2.5, минимум 1.3.
        var easeFactor: Double = 2.5
        
        /// Текущий интервал в днях. 0 у новых карточек.
        var intervalDays: Int = 0
        
        /// Количество подряд правильных ответов (оценка ≥ 3).
        var repetitions: Int = 0
        
        /// Когда карточку нужно показать снова. nil = новая, ещё не оценивалась.
        var nextReviewDate: Date? = nil
        
        /// Дата последнего ответа в SRS-режиме.
        var lastReviewDate: Date? = nil
        
        // MARK: - Relationships
        
        @Relationship(inverse: \CardGroup.cards)
        var groups: [CardGroup] = []
        
        // MARK: - Init
        
        init(
            origin: String,
            translated: String,
            originDescription: String = "",
            translatedDescription: String = "",
            dateAdded: Date = .now
        ) {
            self.id = UUID()
            self.originWord = origin
            self.translatedWord = translated
            self.originDescription = originDescription
            self.translatedDescription = translatedDescription
            self.isFavourite = false
            self.dateAdded = dateAdded
            self.correctCount = 0
            self.wrongCount = 0
            
            self.easeFactor = SRSAlgorithm.defaultEaseFactor
            self.intervalDays = 0
            self.repetitions = 0
            self.nextReviewDate = nil
            self.lastReviewDate = nil
        }
        
        // MARK: - Computed
        
        var hasOriginDescription: Bool {
            !originDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
            
        var hasTranslatedDescription: Bool {
            !translatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var totalAttempts: Int {
            correctCount + wrongCount
        }
        
        var successRate: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(correctCount) / Double(totalAttempts)
        }
        
        // MARK: - SRS helpers
        
        /// Карточка ещё ни разу не оценивалась в SRS-режиме.
        var isNewInSRS: Bool {
            lastReviewDate == nil
        }
        
        /// Пора повторять сегодня (или карточка новая).
        var isDueToday: Bool {
            guard let next = nextReviewDate else { return true }
            let endOfToday = StudyDay.end(of: .now)
            return next < endOfToday
        }
    }
    @Model
    final class CardGroup {
        @Attribute(.unique) var id: UUID
        var name: String
        
        /// nil для пользовательских групп.
        /// Непустое значение только для legacy-мигрированных данных
        /// или если в будущем понадобится хранить системные группы.
        var systemTypeRaw: String?
        
        var createdAt: Date
        var orderIndex: Int
        
        var cards: [Card] = []
        
        init(
            name: String,
            systemType: SystemGroupType? = nil,
            orderIndex: Int = 0
        ) {
            self.id = UUID()
            self.name = name
            self.systemTypeRaw = systemType?.rawValue
            self.createdAt = .now
            self.orderIndex = orderIndex
        }
        
        // MARK: - System type
        
        var systemType: SystemGroupType? {
            get { systemTypeRaw.flatMap(SystemGroupType.init(rawValue:)) }
            set { systemTypeRaw = newValue?.rawValue }
        }
        
        var isSystem: Bool {
            systemType != nil
        }
        
        /// Отображаемое имя (локализованное для системных, обычное для пользовательских)
        var displayName: String {
            if let type = systemType {
                return type.localizedNameKey.localized()
            }
            return name
        }
    }
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
