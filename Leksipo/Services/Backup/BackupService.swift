//
//  BackupService.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.10.2026.
//

import Foundation
import SwiftData

@MainActor
enum BackupService {
    
    // MARK: - Export
    
    static func createBackup(context: ModelContext) throws -> Data {
        let cards = try context.fetch(FetchDescriptor<Card>())
        let groups = try context.fetch(FetchDescriptor<CardGroup>())
        let stats = try context.fetch(FetchDescriptor<DailyStat>())
        
        // Настройки (singleton)
        let settingsPredicate = #Predicate<UserSettings> { $0.id == "singleton" }
        let settingsArray = try context.fetch(FetchDescriptor<UserSettings>(predicate: settingsPredicate))
        guard let settings = settingsArray.first else {
            throw NSError(domain: "Backup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Settings not found"])
        }
        
        // Маппинг SwiftData -> DTO
        let backupCards = cards.map { card in
            BackupCard(
                id: card.id,
                originWord: card.originWord,
                translatedWord: card.translatedWord,
                originDescription: card.originDescription,
                translatedDescription: card.translatedDescription,
                isFavourite: card.isFavourite,
                dateAdded: card.dateAdded,
                correctCount: card.correctCount,
                wrongCount: card.wrongCount,
                easeFactor: card.easeFactor,
                intervalDays: card.intervalDays,
                repetitions: card.repetitions,
                nextReviewDate: card.nextReviewDate,
                lastReviewDate: card.lastReviewDate,
                groupIDs: card.groups.map(\.id)
            )
        }
        
        let backupGroups = groups.map { group in
            BackupGroup(
                id: group.id,
                name: group.name,
                createdAt: group.createdAt,
                orderIndex: group.orderIndex
            )
        }
        
        let backupStats = stats.map { stat in
            BackupDailyStat(
                dateKey: stat.dateKey,
                date: stat.date,
                solvedCount: stat.solvedCount,
                goalCompleted: stat.goalCompleted,
                srsCleared: stat.srsCleared,
                srsNewCardsIntroduced: stat.srsNewCardsIntroduced,
                srsReviewCount: stat.srsReviewCount,
                srsNextDueDayKey: stat.srsNextDueDayKey
            )
        }
        
        let backupSettings = BackupUserSettings(
            dailyGoal: settings.dailyGoal,
            streak: settings.streak,
            totalSolved: settings.totalSolved,
            lastActiveDate: settings.lastActiveDate,
            dailyGoalRewarded: settings.dailyGoalRewarded,
            srsStreak: settings.srsStreak,
            unlockedAchievementIDs: settings.unlockedAchievementIDs,
            achievementUnlockDates: settings.achievementUnlockDates
        )
        
        let root = BackupRoot(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            exportDate: .now,
            cards: backupCards,
            groups: backupGroups,
            stats: backupStats,
            settings: backupSettings
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(root)
    }
    
    // MARK: - Import (Restore)
    
    static func restoreBackup(from data: Data, context: ModelContext, transaction: PersistenceTransaction? = nil) throws {
        let backup = try validatedBackup(from: data)
        let transaction = transaction ?? PersistenceTransaction(context: context)
        try transaction.perform {
            // Обновляем совпадающие UUID на месте: delete+insert одного unique ID
            // в одном save может превратиться в неявный upsert SwiftData.
            let oldCards = try context.fetch(FetchDescriptor<Card>())
            let oldGroups = try context.fetch(FetchDescriptor<CardGroup>())
            let oldStats = try context.fetch(FetchDescriptor<DailyStat>())
            let oldSettings = try context.fetch(FetchDescriptor<UserSettings>())
            oldCards.forEach { transaction.track($0) }
            oldGroups.forEach { transaction.track($0) }
            oldStats.forEach { transaction.track($0) }
            oldSettings.forEach { transaction.track($0) }
            var groupMap = Dictionary(uniqueKeysWithValues: oldGroups.map { ($0.id, $0) })
            let cardMap = Dictionary(uniqueKeysWithValues: oldCards.map { ($0.id, $0) })
            let statMap = Dictionary(uniqueKeysWithValues: oldStats.map { ($0.dateKey, $0) })
            for g in backup.groups {
                let group = groupMap[g.id] ?? CardGroup(name: g.name, orderIndex: g.orderIndex)
                if groupMap[g.id] == nil { context.insert(group) }
                group.id = g.id
                group.name = g.name
                group.orderIndex = g.orderIndex
                group.createdAt = g.createdAt
                groupMap[g.id] = group
            }
            for c in backup.cards {
                let card = cardMap[c.id] ?? Card(origin: c.originWord, translated: c.translatedWord)
                if cardMap[c.id] == nil { context.insert(card) }
                card.id = c.id
                card.originWord = c.originWord
                card.translatedWord = c.translatedWord
                card.originDescription = c.originDescription
                card.translatedDescription = c.translatedDescription
                card.dateAdded = c.dateAdded
                card.isFavourite = c.isFavourite
                card.correctCount = c.correctCount
                card.wrongCount = c.wrongCount
                card.easeFactor = c.easeFactor
                card.intervalDays = c.intervalDays
                card.repetitions = c.repetitions
                card.nextReviewDate = c.nextReviewDate
                card.lastReviewDate = c.lastReviewDate
                card.groups = try c.groupIDs.map {
                    guard let group = groupMap[$0] else { throw PersistenceError.invalidBackup }
                    return group
                }
            }
            let cardIDs = Set(backup.cards.map(\.id))
            let groupIDs = Set(backup.groups.map(\.id))
            let statKeys = Set(backup.stats.map(\.dateKey))
            for card in oldCards where !cardIDs.contains(card.id) { context.delete(card) }
            for group in oldGroups where !groupIDs.contains(group.id) { context.delete(group) }
            for stat in oldStats where !statKeys.contains(stat.dateKey) { context.delete(stat) }
            for s in backup.stats {
                let stat = statMap[s.dateKey] ?? DailyStat(date: s.date)
                if statMap[s.dateKey] == nil { context.insert(stat) }
                stat.dateKey = s.dateKey
                stat.date = s.date
                stat.solvedCount = s.solvedCount
                stat.goalCompleted = s.goalCompleted
                stat.srsCleared = s.srsCleared
                stat.srsNewCardsIntroduced = s.srsNewCardsIntroduced ?? 0
                stat.srsReviewCount = s.srsReviewCount ?? 0
                stat.srsNextDueDayKey = s.srsNextDueDayKey
            }
            let settings = oldSettings.first(where: { $0.id == "singleton" }) ?? UserSettings()
            if settings.modelContext == nil { context.insert(settings) }
            for old in oldSettings where old !== settings { context.delete(old) }
            settings.dailyGoal = backup.settings.dailyGoal
            settings.streak = backup.settings.streak
            settings.totalSolved = backup.settings.totalSolved
            settings.lastActiveDate = backup.settings.lastActiveDate
            settings.dailyGoalRewarded = backup.settings.dailyGoalRewarded
            settings.srsStreak = backup.settings.srsStreak
            settings.unlockedAchievementIDs = backup.settings.unlockedAchievementIDs
            settings.achievementUnlockDates = backup.settings.achievementUnlockDates
            // Сброс очередей и маркер миграции фиксируются вместе с заменой базы.
            settings.solveSessionsData = Data("{}".utf8)
            settings.legacyMigrationCompleted = true
        }
    }

    static func validatedBackup(from data: Data) throws -> BackupRoot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup: BackupRoot
        do { backup = try decoder.decode(BackupRoot.self, from: data) }
        catch { throw PersistenceError.invalidBackup }
        guard backup.schemaVersion == 1 || (backup.schemaVersion == nil && backup.version == "2.9.0") else {
            throw PersistenceError.unsupportedBackup
        }
        func require(_ condition: Bool) throws {
            if !condition { throw PersistenceError.invalidBackup }
        }
        func count(_ value: Int) -> Bool { (0...1_000_000_000).contains(value) }
        func date(_ value: Date) -> Bool {
            value.timeIntervalSince1970.isFinite && (-62_135_596_800...253_402_300_799).contains(value.timeIntervalSince1970)
        }
        func text(_ value: String) -> Bool { !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        try require(date(backup.exportDate))
        let groupIDs = Set(backup.groups.map(\.id))
        try require(groupIDs.count == backup.groups.count)
        try require(Set(backup.cards.map(\.id)).count == backup.cards.count)
        try require(Set(backup.stats.map(\.dateKey)).count == backup.stats.count)
        for g in backup.groups {
            try require(text(g.name) && count(g.orderIndex) && date(g.createdAt))
        }
        for c in backup.cards {
            try require(text(c.originWord) && text(c.translatedWord))
            try require(count(c.correctCount) && count(c.wrongCount) && count(c.repetitions))
            try require(c.easeFactor.isFinite && (1.3...100).contains(c.easeFactor))
            try require((0...365_000).contains(c.intervalDays))
            try require(date(c.dateAdded) && (c.lastReviewDate.map(date) ?? true))
            try require(c.nextReviewDate.map(date) ?? true)
            try require((c.lastReviewDate == nil) == (c.nextReviewDate == nil))
            if let last = c.lastReviewDate, let next = c.nextReviewDate {
                try require(c.intervalDays >= 1 && next > last)
            } else {
                try require(c.intervalDays == 0 && c.repetitions == 0)
            }
            try require(Set(c.groupIDs).count == c.groupIDs.count && Set(c.groupIDs).isSubset(of: groupIDs))
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        for s in backup.stats {
            guard let keyDate = formatter.date(from: s.dateKey), formatter.string(from: keyDate) == s.dateKey else {
                throw PersistenceError.invalidBackup
            }
            // dateKey — локальный день при создании записи; зона могла измениться.
            try require(count(s.srsNewCardsIntroduced ?? 0) && count(s.srsReviewCount ?? 0))
            if let next = s.srsNextDueDayKey {
                guard let parsed = formatter.date(from: next), formatter.string(from: parsed) == next else { throw PersistenceError.invalidBackup }
                try require(next >= s.dateKey)
            }
            try require(date(s.date) && abs(keyDate.timeIntervalSince(s.date)) <= 86_400 && count(s.solvedCount))
        }
        let s = backup.settings
        try require((1...100).contains(s.dailyGoal) && count(s.streak) && count(s.srsStreak) && count(s.totalSolved) && date(s.lastActiveDate))
        let unlocked = Set(s.unlockedAchievementIDs)
        try require(unlocked.count == s.unlockedAchievementIDs.count)
        try require(Set(s.achievementUnlockDates.keys).isSubset(of: unlocked))
        try require(s.achievementUnlockDates.values.allSatisfy(date))
        return backup
    }
}
