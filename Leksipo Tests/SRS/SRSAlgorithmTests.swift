//
//  SRSAlgorithmTests.swift
//  Leksipo
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
@testable import English_Words

@Suite("SRSAlgorithm — чистый SM-2")
struct SRSAlgorithmTests {
    
    // MARK: - Фиксированная дата для детерминизма
    
    /// 15 января 2026, 14:30. Не DST-переход → стабильно на любом CI.
    private let refDate: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 1
        c.day = 15
        c.hour = 14
        c.minute = 30
        return Calendar.current.date(from: c)!
    }()
    
    private func expectedNextDate(from date: Date, days: Int) -> Date {
        let cal = Calendar.current
        let added = cal.date(byAdding: .day, value: days, to: date)!
        return cal.startOfDay(for: added)
    }
    
    // MARK: - Константы
    
    @Test("defaultEaseFactor равен 2.5")
    func defaultEaseFactorValue() {
        #expect(SRSAlgorithm.defaultEaseFactor == 2.5)
    }
    
    @Test("minimumEaseFactor равен 1.3")
    func minimumEaseFactorValue() {
        #expect(SRSAlgorithm.minimumEaseFactor == 1.3)
    }
    
    // MARK: - Правильные ответы (q >= 3)
    
    @Test("Первый правильный (q=4): интервал 1, repetitions 1, EF не меняется, next = +1 день")
    func firstCorrectAnswer() {
        let p = SRSAlgorithm.predict(
            quality: 4,
            currentEaseFactor: 2.5,
            currentIntervalDays: 0,
            currentRepetitions: 0,
            from: refDate
        )
        #expect(p.intervalDays == 1)
        #expect(p.repetitions == 1)
        #expect(abs(p.easeFactor - 2.5) < 1e-9)
        #expect(p.nextReviewDate == expectedNextDate(from: refDate, days: 1))
    }
    
    @Test("Второй правильный (q=4): интервал 6, repetitions 2")
    func secondCorrectAnswer() {
        let p = SRSAlgorithm.predict(
            quality: 4,
            currentEaseFactor: 2.5,
            currentIntervalDays: 1,
            currentRepetitions: 1,
            from: refDate
        )
        #expect(p.intervalDays == 6)
        #expect(p.repetitions == 2)
        #expect(abs(p.easeFactor - 2.5) < 1e-9)
    }
    
    @Test("Третий правильный (q=4): интервал = ceil(prev * EF) = 15")
    func thirdCorrectAnswer() {
        let p = SRSAlgorithm.predict(
            quality: 4,
            currentEaseFactor: 2.5,
            currentIntervalDays: 6,
            currentRepetitions: 2,
            from: refDate
        )
        #expect(p.intervalDays == 15) // ceil(6 * 2.5)
        #expect(p.repetitions == 3)
    }
    
    @Test("Четвёртый правильный: ceil(15 * 2.5) = 38 (округление вверх)")
    func fourthCorrectAnswer() {
        let p = SRSAlgorithm.predict(
            quality: 4,
            currentEaseFactor: 2.5,
            currentIntervalDays: 15,
            currentRepetitions: 3,
            from: refDate
        )
        #expect(p.intervalDays == 38) // 37.5 → 38
        #expect(p.repetitions == 4)
    }
    
    // MARK: - Неправильные ответы (q < 3)
    
    @Test(
        "Неправильный ответ (q<3): repetitions сбрасывается в 0, интервал = 1",
        arguments: [0, 1, 2]
    )
    func wrongAnswerResets(quality: Int) {
        let p = SRSAlgorithm.predict(
            quality: quality,
            currentEaseFactor: 2.5,
            currentIntervalDays: 10,
            currentRepetitions: 5,
            from: refDate
        )
        #expect(p.repetitions == 0)
        #expect(p.intervalDays == 1)
        #expect(p.nextReviewDate == expectedNextDate(from: refDate, days: 1))
    }
    
    // MARK: - Направление изменения EF
    
    @Test("q=5 увеличивает EF на ~0.1")
    func easyIncreasesEF() {
        let p = SRSAlgorithm.predict(
            quality: 5,
            currentEaseFactor: 2.5,
            currentIntervalDays: 0,
            currentRepetitions: 0,
            from: refDate
        )
        #expect(abs(p.easeFactor - 2.6) < 1e-9)
    }
    
    @Test("q=4 не меняет EF")
    func goodKeepsEF() {
        let p = SRSAlgorithm.predict(
            quality: 4,
            currentEaseFactor: 2.5,
            currentIntervalDays: 0,
            currentRepetitions: 0,
            from: refDate
        )
        #expect(abs(p.easeFactor - 2.5) < 1e-9)
    }
    
    @Test("q=3 уменьшает EF на ~0.14")
    func hardDecreasesEF() {
        let p = SRSAlgorithm.predict(
            quality: 3,
            currentEaseFactor: 2.5,
            currentIntervalDays: 0,
            currentRepetitions: 0,
            from: refDate
        )
        #expect(abs(p.easeFactor - 2.36) < 1e-9)
    }
    
    @Test("q=0 при EF=2.5: EF падает на 0.8 → 1.7")
    func blackoutDropsEF() {
        let p = SRSAlgorithm.predict(
            quality: 0,
            currentEaseFactor: 2.5,
            currentIntervalDays: 5,
            currentRepetitions: 3,
            from: refDate
        )
        #expect(abs(p.easeFactor - 1.7) < 1e-9)
    }
    
    // MARK: - Границы EF
    
    @Test("EF не падает ниже 1.3 (q=0 при EF=1.3)")
    func efAtMinimumStays() {
        let p = SRSAlgorithm.predict(
            quality: 0,
            currentEaseFactor: 1.3,
            currentIntervalDays: 0,
            currentRepetitions: 0,
            from: refDate
        )
        #expect(abs(p.easeFactor - 1.3) < 1e-9)
    }
    
    @Test("EF зажимается снизу (q=0 при EF=1.4 → 1.3, не 0.6)")
    func efClampedAtMinimum() {
        let p = SRSAlgorithm.predict(
            quality: 0,
            currentEaseFactor: 1.4,
            currentIntervalDays: 0,
            currentRepetitions: 0,
            from: refDate
        )
        #expect(abs(p.easeFactor - 1.3) < 1e-9)
    }
    
    // MARK: - Кламп quality
    
    @Test("quality клампится снизу: -1 ≡ 0")
    func qualityClampedBelow() {
        let a = SRSAlgorithm.predict(
            quality: -1, currentEaseFactor: 2.5,
            currentIntervalDays: 3, currentRepetitions: 2, from: refDate
        )
        let b = SRSAlgorithm.predict(
            quality: 0, currentEaseFactor: 2.5,
            currentIntervalDays: 3, currentRepetitions: 2, from: refDate
        )
        #expect(a == b)
    }
    
    @Test("quality клампится сверху: 6 ≡ 5")
    func qualityClampedAbove() {
        let a = SRSAlgorithm.predict(
            quality: 6, currentEaseFactor: 2.5,
            currentIntervalDays: 3, currentRepetitions: 2, from: refDate
        )
        let b = SRSAlgorithm.predict(
            quality: 5, currentEaseFactor: 2.5,
            currentIntervalDays: 3, currentRepetitions: 2, from: refDate
        )
        #expect(a == b)
    }
    
    // MARK: - nextReviewDate — нормализация
    
    @Test("nextReviewDate всегда на начале дня, независимо от времени исходной даты")
    func nextDateIsStartOfDay() {
        var morningComponents = DateComponents()
        morningComponents.year = 2026
        morningComponents.month = 1
        morningComponents.day = 15
        morningComponents.hour = 6
        let morning = Calendar.current.date(from: morningComponents)!
        
        let p = SRSAlgorithm.predict(
            quality: 4,
            currentEaseFactor: 2.5,
            currentIntervalDays: 6,
            currentRepetitions: 2,
            from: morning
        )
        
        let cal = Calendar.current
        #expect(p.nextReviewDate == cal.startOfDay(for: p.nextReviewDate))
    }
    
    // MARK: - previewIntervalDays ≡ predict.intervalDays
    
    @Test(
        "previewIntervalDays для всех q ∈ 0...5 совпадает с predict.intervalDays",
        arguments: Array(0...5)
    )
    func previewMatchesPredict(quality: Int) {
        let preview = SRSAlgorithm.previewIntervalDays(
            quality: quality,
            currentEaseFactor: 2.5,
            currentIntervalDays: 6,
            currentRepetitions: 2
        )
        let predict = SRSAlgorithm.predict(
            quality: quality,
            currentEaseFactor: 2.5,
            currentIntervalDays: 6,
            currentRepetitions: 2,
            from: refDate
        )
        #expect(preview == predict.intervalDays)
    }
    
    // MARK: - Prediction Equatable
    
    @Test("Prediction сравнивается по значению")
    func predictionEquatable() {
        let a = SRSAlgorithm.predict(
            quality: 4, currentEaseFactor: 2.5,
            currentIntervalDays: 0, currentRepetitions: 0, from: refDate
        )
        let b = SRSAlgorithm.predict(
            quality: 4, currentEaseFactor: 2.5,
            currentIntervalDays: 0, currentRepetitions: 0, from: refDate
        )
        #expect(a == b)
    }
    
    // MARK: - Сквозной сценарий
    
    @Test("Серия q=4 при EF=2.5: интервалы 1 → 6 → 15 → 38")
    func sequenceOfCorrectAnswers() {
        let expected = [1, 6, 15, 38]
        var interval = 0
        var reps = 0
        
        for (step, exp) in expected.enumerated() {
            let p = SRSAlgorithm.predict(
                quality: 4,
                currentEaseFactor: 2.5,
                currentIntervalDays: interval,
                currentRepetitions: reps,
                from: refDate
            )
            #expect(p.intervalDays == exp, "Шаг \(step + 1)")
            interval = p.intervalDays
            reps = p.repetitions
        }
    }
}


extension SRSAlgorithmTests {
    @Test("Дробный интервал округляется вверх даже при дробной части меньше 0.5")
    func fractionalIntervalRoundsUp() {
        let prediction = SRSAlgorithm.predict(quality: 5, currentEaseFactor: 2.36,
            currentIntervalDays: 6, currentRepetitions: 2, from: refDate)
        #expect(prediction.intervalDays == 15) // 14.16, не 14 и не 15.36 с новым EF.
        #expect(abs(prediction.easeFactor - 2.46) < 1e-9)
    }

    @Test("Повреждённые числа не приводят к переполнению", arguments: [Double.nan, .infinity, -.infinity, -1, Double.greatestFiniteMagnitude])
    func extremeStateIsSafe(ease: Double) {
        let prediction = SRSAlgorithm.predict(quality: 5, currentEaseFactor: ease,
            currentIntervalDays: Int.max, currentRepetitions: Int.max, from: refDate)
        #expect((1...365_000).contains(prediction.intervalDays))
        #expect((1.3...100).contains(prediction.easeFactor))
        #expect(prediction.repetitions == 1_000_000_000)
        #expect(prediction.nextReviewDate > refDate)
    }

    @Test("Закрепление не увеличивает интервал, число повторений и EF", arguments: [3, 4, 5])
    func relearningDoesNotAdvanceSchedule(quality: Int) {
        let prediction = SRSAlgorithm.predict(quality: quality, currentEaseFactor: 2.36,
            currentIntervalDays: 15, currentRepetitions: 3, isRelearning: true, from: refDate)
        #expect(prediction.intervalDays == 15)
        #expect(prediction.repetitions == 3)
        #expect(prediction.easeFactor == 2.36)
    }

    @Test("Ошибка во время закрепления сбрасывает длинный интервал")
    func relearningFailureResetsSchedule() {
        let prediction = SRSAlgorithm.predict(quality: 1, currentEaseFactor: 2.36,
            currentIntervalDays: 15, currentRepetitions: 3, isRelearning: true, from: refDate)
        #expect(prediction.intervalDays == 1)
        #expect(prediction.repetitions == 0)
    }
}
