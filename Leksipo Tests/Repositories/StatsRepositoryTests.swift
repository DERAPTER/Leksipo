//
//  StatsRepositoryTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
import SwiftData
@testable import English_Words

@Suite("SwiftDataStatsRepository")
@MainActor
struct StatsRepositoryTests {
    
    let repos: TestContainer.Repositories
    
    init() throws {
        repos = try TestContainer.makeRepositories()
    }
    
    // MARK: - Helpers
    
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h
        return Calendar.current.date(from: c)!
    }
    
    @discardableResult
    private func insertStat(
        date: Date,
        solvedCount: Int = 0,
        goalCompleted: Bool = false
    ) throws -> DailyStat {
        let stat = DailyStat(date: date, solvedCount: solvedCount, goalCompleted: goalCompleted)
        repos.container.mainContext.insert(stat)
        try repos.container.mainContext.save()
        return stat
    }
    
    // MARK: - settings()
    
    @Test("settings() создаёт singleton с id == 'singleton'")
    func settingsCreatesSingleton() throws {
        let s = try repos.stats.settings()
        #expect(s.id == "singleton")
    }
    
    @Test("settings() при повторном вызове возвращает тот же объект")
    func settingsIdempotent() throws {
        let s1 = try repos.stats.settings()
        let s2 = try repos.stats.settings()
        #expect(s1.id == s2.id)
    }
    
    @Test("settings() при инициализации имеет дефолтные значения")
    func settingsDefaults() throws {
        let s = try repos.stats.settings()
        #expect(s.dailyGoal == 20)
        #expect(s.streak == 0)
        #expect(s.totalSolved == 0)
        #expect(s.dailyGoalRewarded == false)
        #expect(s.unlockedAchievementIDs.isEmpty)
    }
    
    // MARK: - updateDailyGoal
    
    @Test("updateDailyGoal: клампит снизу до 1")
    func updateDailyGoalClampsLow() throws {
        try repos.stats.updateDailyGoal(0)
        #expect(try repos.stats.settings().dailyGoal == 1)
        
        try repos.stats.updateDailyGoal(-5)
        #expect(try repos.stats.settings().dailyGoal == 1)
    }
    
    @Test("updateDailyGoal: клампит сверху до 100")
    func updateDailyGoalClampsHigh() throws {
        try repos.stats.updateDailyGoal(200)
        #expect(try repos.stats.settings().dailyGoal == 100)
    }
    
    @Test("updateDailyGoal: валидное значение сохраняется")
    func updateDailyGoalValid() throws {
        try repos.stats.updateDailyGoal(50)
        #expect(try repos.stats.settings().dailyGoal == 50)
    }
    
    // MARK: - recordSolved: базовый инкремент
    
    @Test("recordSolved: увеличивает totalSolved и сегодняшний solvedCount")
    func recordSolvedIncrements() throws {
        let change = try repos.stats.recordSolved(on: .now)
        #expect(change.newTotalSolved == 1)
        #expect(change.newTodaySolved == 1)
        
        let s = try repos.stats.settings()
        #expect(s.totalSolved == 1)
    }
    
    @Test("recordSolved: несколько вызовов в один день накапливают счётчик")
    func recordSolvedAccumulates() throws {
        let day = date(2026, 3, 15)
        _ = try repos.stats.recordSolved(on: day)
        _ = try repos.stats.recordSolved(on: day)
        let change = try repos.stats.recordSolved(on: day)
        #expect(change.newTodaySolved == 3)
        #expect(change.newTotalSolved == 3)
    }
    
    // MARK: - recordSolved: goalJustCompleted
    
    @Test("recordSolved: goalJustCompleted = true ровно один раз — в момент достижения цели")
    func goalJustCompletedFiresOnce() throws {
        try repos.stats.updateDailyGoal(3)
        let day = date(2026, 3, 15)
        
        let c1 = try repos.stats.recordSolved(on: day)
        #expect(c1.goalJustCompleted == false)
        
        let c2 = try repos.stats.recordSolved(on: day)
        #expect(c2.goalJustCompleted == false)
        
        let c3 = try repos.stats.recordSolved(on: day)
        #expect(c3.goalJustCompleted == true)
        
        // Дальше — уже false, потому что goalCompleted установлен
        let c4 = try repos.stats.recordSolved(on: day)
        #expect(c4.goalJustCompleted == false)
    }
    
    @Test("recordSolved: dailyGoalRewarded сбрасывается при смене дня")
    func dailyGoalRewardedResetsOnNewDay() throws {
        try repos.stats.updateDailyGoal(1)
        
        // День 1 — выполняем цель
        _ = try repos.stats.recordSolved(on: date(2026, 3, 15))
        #expect(try repos.stats.settings().dailyGoalRewarded == true)
        
        // День 2 — смена дня сбрасывает флаг
        _ = try repos.stats.recordSolved(on: date(2026, 3, 16))
        // После первого вызова дня флаг сбросился и потом сразу выставился обратно (goal=1)
        // Проверяем на дне с goal=5:
        try repos.stats.updateDailyGoal(5)
        _ = try repos.stats.recordSolved(on: date(2026, 3, 17))
        #expect(try repos.stats.settings().dailyGoalRewarded == false)
    }
    
    @Test("recordSolved: newStreak в StatsChange отражает актуальный streak")
    func recordSolvedReturnsStreak() throws {
        try repos.stats.updateDailyGoal(1)
        let change = try repos.stats.recordSolved(on: date(2026, 3, 15))
        #expect(change.newStreak == 1)
    }
    
    // MARK: - recordSolved: streak
    
    @Test("streak = 1 после первого выполнения цели")
    func streakFirstCompletion() throws {
        try repos.stats.updateDailyGoal(1)
        _ = try repos.stats.recordSolved(on: date(2026, 3, 15))
        #expect(try repos.stats.settings().streak == 1)
    }
    
    @Test("streak увеличивается при выполнении цели два дня подряд")
    func streakTwoConsecutiveDays() throws {
        try repos.stats.updateDailyGoal(1)
        
        _ = try repos.stats.recordSolved(on: date(2026, 3, 15))
        #expect(try repos.stats.settings().streak == 1)
        
        _ = try repos.stats.recordSolved(on: date(2026, 3, 16))
        #expect(try repos.stats.settings().streak == 2)
    }
    
    @Test("streak сбрасывается в 1 при разрыве серии")
    func streakResetsOnGap() throws {
        try repos.stats.updateDailyGoal(1)
        
        _ = try repos.stats.recordSolved(on: date(2026, 3, 15))
        #expect(try repos.stats.settings().streak == 1)
        
        // Пропускаем 16-е, выполняем 17-е
        _ = try repos.stats.recordSolved(on: date(2026, 3, 17))
        #expect(try repos.stats.settings().streak == 1)
    }
    
    // MARK: - activity(for:)
    
    @Test("activity(for:) → nil, если записи нет")
    func activityNilWhenAbsent() throws {
        #expect(try repos.stats.activity(for: date(2026, 3, 15)) == nil)
    }
    
    @Test("activity(for:) возвращает запись по дате")
    func activityReturnsRecord() throws {
        try insertStat(date: date(2026, 3, 15), solvedCount: 7, goalCompleted: true)
        let stat = try repos.stats.activity(for: date(2026, 3, 15, 20)) // время не важно
        #expect(stat?.solvedCount == 7)
        #expect(stat?.goalCompleted == true)
    }
    
    // MARK: - activityHistory(monthsBack:)
    
    @Test("activityHistory: возвращает только записи в пределах N месяцев")
    func activityHistoryFiltersByMonths() throws {
        let calendar = Calendar.current
        let now = Date()
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now)!
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        
        try insertStat(date: twoMonthsAgo)
        try insertStat(date: oneMonthAgo)
        try insertStat(date: now)
        
        let history = try repos.stats.activityHistory(monthsBack: 1)
        // Должны попасть только записи за последний месяц
        #expect(history.count == 2)
    }
    
    @Test("activityHistory: включает день ровно N месяцев назад (граница включительна)")
    func activityHistoryIncludesBoundaryDay() throws {
        let calendar = Calendar.current
        let now = Date()
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) else {
            Issue.record("Не удалось посчитать дату")
            return
        }
        
        // Запись «ровно месяц назад» (в разное время суток — не важно)
        try insertStat(date: oneMonthAgo, solvedCount: 1, goalCompleted: true)
        
        let history = try repos.stats.activityHistory(monthsBack: 1)
        #expect(history.count == 1, "День ровно N месяцев назад должен попадать в историю")
    }
    
    @Test("activityHistory: сортировка по дате ASC (от старых к новым)")
    func activityHistorySorted() throws {
        try insertStat(date: date(2026, 3, 17))
        try insertStat(date: date(2026, 3, 15))
        try insertStat(date: date(2026, 3, 16))
        
        let history = try repos.stats.activityHistory(monthsBack: 24)
        let days = history.map { Calendar.current.component(.day, from: $0.date) }
        #expect(days == [15, 16, 17])
    }
    
    // MARK: - isDateActive
    
    @Test("isDateActive: false, если записи нет")
    func isDateActiveNoRecord() throws {
        #expect(try repos.stats.isDateActive(date(2026, 3, 15)) == false)
    }
    
    @Test("isDateActive: false, если запись есть, но goalCompleted = false")
    func isDateActiveRecordNotCompleted() throws {
        try insertStat(date: date(2026, 3, 15), goalCompleted: false)
        #expect(try repos.stats.isDateActive(date(2026, 3, 15)) == false)
    }
    
    @Test("isDateActive: true, если запись есть и goalCompleted = true")
    func isDateActiveCompleted() throws {
        try insertStat(date: date(2026, 3, 15), goalCompleted: true)
        #expect(try repos.stats.isDateActive(date(2026, 3, 15)) == true)
    }
    
    // MARK: - totalDaysGoalCompleted
    
    @Test("totalDaysGoalCompleted: считает только goalCompleted")
    func totalDaysGoalCompleted() throws {
        try insertStat(date: date(2026, 3, 14), goalCompleted: true)
        try insertStat(date: date(2026, 3, 15), goalCompleted: false)
        try insertStat(date: date(2026, 3, 16), goalCompleted: true)
        try insertStat(date: date(2026, 3, 17), goalCompleted: true)
        
        #expect(try repos.stats.totalDaysGoalCompleted() == 3)
    }
    
    @Test("totalDaysGoalCompleted: пустая база → 0")
    func totalDaysGoalCompletedEmpty() throws {
        #expect(try repos.stats.totalDaysGoalCompleted() == 0)
    }
    
    // MARK: - resetAllStats
    
    @Test("resetAllStats: удаляет все DailyStat")
    func resetDeletesAllStats() throws {
        try insertStat(date: date(2026, 3, 14), goalCompleted: true)
        try insertStat(date: date(2026, 3, 15), goalCompleted: true)
        
        try repos.stats.resetAllStats()
        
        #expect(try repos.stats.activityHistory(monthsBack: 24).isEmpty)
    }
    
    @Test("resetAllStats: обнуляет streak и totalSolved")
    func resetClearsCounters() throws {
        try repos.stats.updateDailyGoal(1)
        _ = try repos.stats.recordSolved(on: date(2026, 3, 15))
        
        try repos.stats.resetAllStats()
        
        let s = try repos.stats.settings()
        #expect(s.streak == 0)
        #expect(s.totalSolved == 0)
        #expect(s.dailyGoalRewarded == false)
    }
    
    @Test("resetAllStats: не трогает dailyGoal")
    func resetKeepsDailyGoal() throws {
        try repos.stats.updateDailyGoal(42)
        try repos.stats.resetAllStats()
        #expect(try repos.stats.settings().dailyGoal == 42)
    }
    
    @Test("resetAllStats: не трогает разблокированные достижения")
    func resetKeepsAchievements() throws {
        let s = try repos.stats.settings()
        s.unlock("cards_10")
        
        try repos.container.mainContext.save()
        try repos.stats.resetAllStats()
        
        #expect(try repos.stats.settings().isUnlocked("cards_10") == true)
    }
    
    // MARK: - Сквозной сценарий: несколько дней подряд
    
    @Test("Полный сценарий: 3 дня подряд с выполненной целью → streak = 3, totalDaysGoalCompleted = 3")
    func multiDayScenario() throws {
        try repos.stats.updateDailyGoal(2)
        
        for day in 15...17 {
            let d = date(2026, 3, day)
            _ = try repos.stats.recordSolved(on: d)
            _ = try repos.stats.recordSolved(on: d) // достигаем цели
        }
        
        #expect(try repos.stats.settings().streak == 3)
        #expect(try repos.stats.totalDaysGoalCompleted() == 3)
        #expect(try repos.stats.settings().totalSolved == 6)
    }
}
