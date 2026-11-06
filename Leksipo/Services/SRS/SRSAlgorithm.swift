//
//  SRSAlgorithm.swift
//  Leksipo
//
//  Created by Егор Халиков on 04.10.2026.
//

import Foundation

/// Плановое расписание SM-2 (SuperMemo 2) и отдельное закрепление.
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
/// интервал ставится в 1 день. EF меняется при плановом ответе.
enum SRSAlgorithm {
    
    static let defaultEaseFactor: Double = 2.5
    static let minimumEaseFactor: Double = 1.3
    // Защитные пределы совпадают с форматом бэкапа; это не параметры SM-2.
    static let maximumEaseFactor: Double = 100
    static let maximumIntervalDays = 365_000
    static let maximumRepetitions = 1_000_000_000
    
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
        isRelearning: Bool = false,
        from date: Date = .now,
        calendar: Calendar = StudyDay.calendar
    ) -> Prediction {
        let q = max(0, min(5, quality))
        let ease = currentEaseFactor.isFinite
            ? min(maximumEaseFactor, max(minimumEaseFactor, currentEaseFactor))
            : defaultEaseFactor
        let repetitions = min(maximumRepetitions, max(0, currentRepetitions))
        let interval = min(maximumIntervalDays, max(1, currentIntervalDays))
        
        let newRepetitions: Int
        let newInterval: Int
        
        if q < 3 {
            newRepetitions = 0
            newInterval = 1
        } else if isRelearning {
            // Закрепление внутри дня не является новым шагом интервального расписания.
            newRepetitions = repetitions
            newInterval = interval
        } else {
            newRepetitions = min(maximumRepetitions, repetitions + 1)
            switch repetitions {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = Int(min(Double(maximumIntervalDays), ceil(Double(interval) * ease)))
            }
        }
        
        // Ease Factor по формуле SM-2
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        // EF оценивает отсроченное вспоминание, а не кратковременное закрепление.
        let newEF = isRelearning ? ease : min(maximumEaseFactor, max(minimumEaseFactor, ease + delta))
        
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
        currentRepetitions: Int,
        isRelearning: Bool = false
    ) -> Int {
        predict(
            quality: quality,
            currentEaseFactor: currentEaseFactor,
            currentIntervalDays: currentIntervalDays,
            currentRepetitions: currentRepetitions,
            isRelearning: isRelearning
        ).intervalDays
    }
}
