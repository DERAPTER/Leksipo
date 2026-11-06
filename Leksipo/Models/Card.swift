//
//  Card.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

/// Карточка — основная сущность приложения.
/// Один экземпляр Card может принадлежать нескольким CardGroup через relationship.
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

    /// Ошибка SRS, после которой ещё не было трёх успешных повторений подряд.
    /// nil у старых карточек: исторические последовательности не восстанавливаем по счётчикам.
    var srsRecoveryPending: Bool? = nil

    /// Незавершённое закрепление после оценки < 4. nil у карточек старой базы.
    /// nextReviewDate при этом хранит плановый интервал, а карточка доступна уже сегодня.
    var srsRelearningPending: Bool? = nil
    
    // MARK: - Relationships
    
    @Relationship(inverse: \CardGroup.cards)
    var groups: [CardGroup] = []
    
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
        if srsRelearningPending == true { return true }
        guard let next = nextReviewDate else { return true }
        let endOfToday = StudyDay.end(of: .now)
        return next < endOfToday
    }
}
