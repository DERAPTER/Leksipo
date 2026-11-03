//
//  SRSAlgorithm.swift
//  English Words
//
//  Created by Егор Халиков on 04.10.2026.
//

import Foundation

/// Классический алгоритм SM-2 (SuperMemo 2).
/// Чистая математика — без SwiftData, UI и зависимостей.
///
/// Оценка q ∈ [0...5]:
/// - 0 — полный провал
/// - 1 — забыл
/// - 2 — почти вспомнил
/// - 3 — вспомнил с трудом
/// - 4 — вспомнил хорошо
/// - 5 — вспомнил легко
///
/// Оценки q < 3 считаются неправильным ответом: repetitions сбрасывается,
/// интервал ставится в 1 день, EF падает.
enum SRSAlgorithm {
    
    static let defaultEaseFactor: Double = 2.5
    static let minimumEaseFactor: Double = 1.3
    
    /// Результат расчёта следующего состояния карточки.
    struct Prediction: Equatable {
        let intervalDays: Int
        let repetitions: Int
        let easeFactor: Double
        let nextReviewDate: Date
    }
    
    /// Считает следующее состояние карточки по SM-2.
    static func predict(
        quality: Int,
        currentEaseFactor: Double,
        currentIntervalDays: Int,
        currentRepetitions: Int,
        from date: Date = .now,
        calendar: Calendar = StudyDay.calendar
    ) -> Prediction {
        let q = max(0, min(5, quality))
        
        let newRepetitions: Int
        let newInterval: Int
        
        if q < 3 {
            newRepetitions = 0
            newInterval = 1
        } else {
            newRepetitions = currentRepetitions + 1
            switch currentRepetitions {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = max(1, Int(round(Double(currentIntervalDays) * currentEaseFactor)))
            }
        }
        
        // Ease Factor по формуле SM-2
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        let newEF = max(minimumEaseFactor, currentEaseFactor + delta)
        
        // Дата следующего повторения — нормализуем к началу дня
        let nextDate = calendar.date(byAdding: .day, value: newInterval, to: date) ?? date
        let normalizedNext = calendar.startOfDay(for: nextDate)
        
        return Prediction(
            intervalDays: newInterval,
            repetitions: newRepetitions,
            easeFactor: newEF,
            nextReviewDate: normalizedNext
        )
    }
    
    /// Удобный шорткат: только интервал в днях — для показа на кнопках.
    /// Не изменяет EF и repetitions.
    static func previewIntervalDays(
        quality: Int,
        currentEaseFactor: Double,
        currentIntervalDays: Int,
        currentRepetitions: Int
    ) -> Int {
        predict(
            quality: quality,
            currentEaseFactor: currentEaseFactor,
            currentIntervalDays: currentIntervalDays,
            currentRepetitions: currentRepetitions
        ).intervalDays
    }
}
