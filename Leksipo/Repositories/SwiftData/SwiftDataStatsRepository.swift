//
//  SwiftDataStatsRepository.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataStatsRepository: StatsRepository {
    private let context: ModelContext
    private let transaction: PersistenceTransaction
    private let calendar: Calendar
    private let now: () -> Date
    
    init(context: ModelContext, transaction: PersistenceTransaction? = nil, calendar: Calendar = StudyDay.calendar, now: @escaping () -> Date = { .now }) {
        self.context = context
        self.calendar = calendar
        self.now = now
        self.transaction = transaction ?? PersistenceTransaction(context: context)
    }
    
    func updateStudyLanguages(_ pair: StudyLanguagePair) throws {
        try transaction.perform {
            let settings = try settings()
            transaction.track(settings)
            settings.languagePair = pair
        }
    }

    // MARK: - Settings
    
    func settings() throws -> UserSettings {
        let predicate = #Predicate<UserSettings> { $0.id == "singleton" }
        var descriptor = FetchDescriptor<UserSettings>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first { return existing }
        return try transaction.perform {
            let created = UserSettings()
            context.insert(created)
            return created
        }
    }
    
    // Совместимость с прежними потребителями; не влияет на ответы, серии и награды.
    func updateDailyGoal(_ goal: Int) throws {
        return try transaction.perform {
            let clamped = max(1, min(100, goal))
            let s = try settings()
            transaction.track(s)
            s.dailyGoal = clamped

        }
    }
    
    func unlockAchievements(_ ids: [String], on date: Date) throws {
        try transaction.perform {
            let s = try settings()
            transaction.track(s)
            for id in ids { s.unlock(id, on: date) }
        }
    }

    // MARK: - Recording

    func recordSRSMilestones(_ milestones: Set<SRSMilestone>) throws {
        guard !milestones.isEmpty else { return }
        try transaction.perform {
            let settings = try settings()
            transaction.track(settings)
            settings.srsMilestonesRaw = milestones.reduce(settings.srsMilestonesRaw ?? 0) { $0 | $1.mask }
        }
    }
    
    func recordSolved(on date: Date) throws -> StatsChange {
        return try transaction.perform {
            let s = try settings()
            transaction.track(s)

            if !calendar.isDate(s.lastActiveDate, inSameDayAs: date) {
                s.lastActiveDate = date
            }

            let todayStat = try statForDate(date) ?? {
                let created = DailyStat(date: date)
                created.dateKey = StudyDay.key(for: date, calendar: calendar)
                created.date = calendar.startOfDay(for: date)
                context.insert(created)
                return created
            }()

            transaction.track(todayStat)
            todayStat.solvedCount += 1
            s.totalSolved += 1

            // Дневная цель и её серия больше не участвуют в новых ответах.
            // Исторические поля остаются для чтения старых баз и бэкапов.
            return StatsChange(
                goalJustCompleted: false,
                newStreak: s.streak,
                newTotalSolved: s.totalSolved,
                newTodaySolved: todayStat.solvedCount,
                dailyGoal: s.dailyGoal
            )
        }
    }
    
    func markSRSCleared(on date: Date) throws {
        return try transaction.perform {
            let s = try settings()
            transaction.track(s)

            if !calendar.isDate(s.lastActiveDate, inSameDayAs: date) {
                s.lastActiveDate = date
            }

            let todayStat = try statForDate(date) ?? {
                let created = DailyStat(date: date)
                created.dateKey = StudyDay.key(for: date, calendar: calendar)
                created.date = calendar.startOfDay(for: date)
                context.insert(created)
                return created
            }()

            // Идемпотентность: не засчитываем один день дважды
            guard !todayStat.srsCleared else { return }

            transaction.track(todayStat)
            todayStat.srsCleared = true
            s.srsStreak = try currentSRSStreak(on: date)

        }
    }
    
    // MARK: - Activity
    
    func activity(for date: Date) throws -> DailyStat? {
        try statForDate(date)
    }
    
    func activityHistory(monthsBack: Int) throws -> [DailyStat] {
        if monthsBack < 0 {
            return try context.fetch(FetchDescriptor<DailyStat>(sortBy: [SortDescriptor(\.dateKey)]))
        }
        guard let rawFrom = calendar.date(byAdding: .month, value: -monthsBack, to: now()) else {
            return []
        }
        let from = calendar.startOfDay(for: rawFrom)
        
        let fromKey = StudyDay.key(for: from, calendar: calendar)
        let predicate = #Predicate<DailyStat> { $0.dateKey >= fromKey }
        let descriptor = FetchDescriptor<DailyStat>(predicate: predicate, sortBy: [SortDescriptor(\.dateKey)])
        return try context.fetch(descriptor)
    }

    func isDateActive(_ date: Date) throws -> Bool {
        guard let stat = try statForDate(date) else { return false }
        return stat.solvedCount > 0 || stat.srsReviewCount > 0 || stat.goalCompleted || stat.srsCleared
    }
    
    func totalDaysGoalCompleted() throws -> Int {
        let predicate = #Predicate<DailyStat> { $0.goalCompleted == true }
        do {
            return try context.fetchCount(FetchDescriptor<DailyStat>(predicate: predicate))
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Reset
    
    func resetAllStats() throws {
        return try transaction.perform {
            do {
                let stats = try context.fetch(FetchDescriptor<DailyStat>())
                for stat in stats {
                    transaction.track(stat)
                    context.delete(stat)
                }

                let s = try settings()
                transaction.track(s)
                s.streak = 0
                s.srsStreak = 0
                s.totalSolved = 0
                s.lastActiveDate = .now
                s.dailyGoalRewarded = false
            } catch let error as RepositoryError {
                throw error
            } catch {
                throw RepositoryError.saveFailed(underlying: error)
            }
        }
    }
    
    // MARK: - Private
    
    private func statForDate(_ date: Date) throws -> DailyStat? {
        let key = StudyDay.key(for: date, calendar: calendar)
        let predicate = #Predicate<DailyStat> { $0.dateKey == key }
        var descriptor = FetchDescriptor<DailyStat>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }

    func currentStreak(on date: Date) throws -> Int {
        let stats = try context.fetch(FetchDescriptor<DailyStat>())
        let completed = Set(stats.filter(\.goalCompleted).map(\.dateKey))
        var day = calendar.startOfDay(for: date)
        if !completed.contains(StudyDay.key(for: day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while completed.contains(StudyDay.key(for: day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    func currentSRSStreak(on date: Date) throws -> Int {
        let todayKey = StudyDay.key(for: date, calendar: calendar)
        let cleared = try context.fetch(FetchDescriptor<DailyStat>())
            .filter { $0.srsCleared && $0.dateKey <= todayKey }
            .sorted { $0.dateKey > $1.dateKey }
        guard let latest = cleared.first,
              let latestDay = StudyDay.date(for: latest.dateKey, calendar: calendar) else { return 0 }
        let today = calendar.startOfDay(for: date)
        let gap = calendar.dateComponents([.day], from: latestDay, to: today).day ?? 0
        // День без назначений считается выполненным. Сегодняшний день с
        // назначениями может быть ещё не окончен, пропущенный вчерашний — разрыв.
        var trailing = 0
        if gap > 0 {
            if let deadline = latest.srsNextDueDayKey {
                guard deadline >= todayKey else { return 0 }
                trailing = deadline == todayKey ? gap - 1 : gap
            } else if gap > 1 {
                return 0 // У старых записей нет сведений о будущих назначениях.
            }
        }
        var count = 1 + trailing
        var newer = latest
        for older in cleared.dropFirst() {
            guard let oldDate = StudyDay.date(for: older.dateKey, calendar: calendar),
                  let newDate = StudyDay.date(for: newer.dateKey, calendar: calendar) else { break }
            let distance = calendar.dateComponents([.day], from: oldDate, to: newDate).day ?? 0
            guard distance == 1 || (older.srsNextDueDayKey.map { $0 >= newer.dateKey } ?? false) else { break }
            count += distance
            newer = older
        }
        return count
    }

    func updateSRSStatus(on date: Date, hasDueCards: Bool, nextReviewDate: Date?) throws {
        try transaction.perform {
            let key = StudyDay.key(for: date, calendar: calendar)
            let settings = try settings()
            transaction.track(settings)
            let stat: DailyStat
            if let existing = try statForDate(date) {
                stat = existing
                transaction.track(stat)
            } else {
                stat = DailyStat(date: date)
                stat.dateKey = key
                stat.date = calendar.startOfDay(for: date)
                context.insert(stat)
            }
            stat.srsCleared = !hasDueCards
            // distantFuture означает, что назначений пока нет; новая карточка
            // уточнит эту границу при следующем обновлении состояния очереди.
            stat.srsNextDueDayKey = nextReviewDate.map { StudyDay.key(for: $0, calendar: calendar) } ?? "9999-12-31"
            if hasDueCards {
                let previous = try context.fetch(FetchDescriptor<DailyStat>())
                    .filter { $0.srsCleared && $0.dateKey < key }.max { $0.dateKey < $1.dateKey }
                if let previous, previous.srsNextDueDayKey.map({ $0 > key }) ?? false {
                    transaction.track(previous)
                    previous.srsNextDueDayKey = key
                }
            }
            settings.srsStreak = try currentSRSStreak(on: date)
        }
    }
}
