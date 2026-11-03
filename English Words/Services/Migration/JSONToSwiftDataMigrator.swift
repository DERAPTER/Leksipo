//
//  JSONToSwiftDataMigrator.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

/// Одноразовая миграция данных из старого JSON-хранилища и UserDefaults в SwiftData.
@MainActor
struct JSONToSwiftDataMigrator {
    private static let completionKey = "swiftdata_migration_v2_completed"
    
    let context: ModelContext
    private let defaults: UserDefaults
    private let sourceURL: URL?
    private let transaction: PersistenceTransaction

    init(context: ModelContext, defaults: UserDefaults = .standard, sourceURL: URL? = nil, transaction: PersistenceTransaction? = nil) {
        self.context = context
        self.defaults = defaults
        self.sourceURL = sourceURL
        self.transaction = transaction ?? PersistenceTransaction(context: context)
    }

    func migrateIfNeeded() throws {
        try transaction.perform {
            let settings = try fetchOrCreateSettings()
            transaction.track(settings)
            guard settings.legacyMigrationCompleted != true else { return }
            if !defaults.bool(forKey: Self.completionKey) { try migrate() }
            // Маркер и перенесённые данные сохраняются одним save, без окна
            // между фиксацией базы и записью отдельного флага UserDefaults.
            settings.legacyMigrationCompleted = true
        }
        // Совместимость со старым ключом; при сбое этой записи новая версия
        // всё равно опирается на маркер, уже зафиксированный в базе.
        defaults.set(true, forKey: Self.completionKey)
    }

    // MARK: - Private
    
    private func migrate() throws {
        // 1. Миграция карточек и групп из старого JSON
        if let legacyDataURL = sourceURL ?? legacyFileURL,
           FileManager.default.fileExists(atPath: legacyDataURL.path) {
            try migrateCards(from: legacyDataURL)
        }
        
        // 2. Миграция статистики и достижений из UserDefaults
        try migrateStatsAndAchievements()
    }
    
    // MARK: - JSON Migration (Cards & Groups)
    
    private func migrateCards(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        // ВАЖНО: Старый DataManager использовал ISO8601 для дат!
        decoder.dateDecodingStrategy = .iso8601
        
        let legacyGroups = try decoder.decode([LegacyCardsGroup].self, from: data)
        
        // 1. Собираем уникальные карточки.
        // Так как в старом коде карточка дублировалась в разных группах,
        // используем словарь [UUID: LegacyCard], чтобы оставить каждую только один раз.
        var uniqueCards: [UUID: LegacyCard] = [:]
        for group in legacyGroups {
            for card in group.cards.cardsArr {
                uniqueCards[card.id] = card
            }
        }
        
        // 2. Собираем все уникальные пользовательские группы.
        var uniqueGroupNames: Set<String> = []
        for card in uniqueCards.values {
            for groupName in card.groups {
                if groupName != "All Cards" && groupName != "Favourites" {
                    uniqueGroupNames.insert(groupName)
                }
            }
        }
        
        // 3. Создаём новые CardGroup
        var groupMap: [String: CardGroup] = [:]
        var orderIndex = 0
        for name in uniqueGroupNames {
            let newGroup = CardGroup(name: name, orderIndex: orderIndex)
            context.insert(newGroup)
            groupMap[name] = newGroup
            orderIndex += 1
        }
        
        // 4. Создаём новые Card и восстанавливаем связи
        for legacyCard in uniqueCards.values {
            let newCard = Card(
                origin: legacyCard.originWord,
                translated: legacyCard.translatedWord,
                dateAdded: legacyCard.dateAdded
            )
            
            newCard.id = legacyCard.id

            // Восстанавливаем счетчики и избранное
            newCard.correctCount = legacyCard.correctCount
            newCard.wrongCount = legacyCard.wrongCount
            newCard.isFavourite = legacyCard.groups.contains("Favourites")
            
            // Привязываем к группам
            var attachedGroups: [CardGroup] = []
            for groupName in legacyCard.groups {
                if let group = groupMap[groupName] {
                    attachedGroups.append(group)
                }
            }
            newCard.groups = attachedGroups
            
            context.insert(newCard)
        }
        
        print("📦 Мигрировано карточек: \(uniqueCards.count), групп: \(groupMap.count)")
    }
    
    // MARK: - UserDefaults Migration (Stats & Achievements)
    
    private func migrateStatsAndAchievements() throws {
        let settings = try fetchOrCreateSettings()
        
        // 1. Статистика
        let oldStreak = defaults.integer(forKey: "streak")
        if oldStreak > 0 { settings.streak = oldStreak }
        
        let oldGoal = defaults.integer(forKey: "dailyGoal")
        if oldGoal > 0 { settings.dailyGoal = oldGoal }
        
        let oldTotalSolved = defaults.integer(forKey: "totalSolved")
        if oldTotalSolved > 0 { settings.totalSolved = oldTotalSolved }
        
        // 2. История активности
        // В старом DataManager это сохранялось как Data (через JSONEncoder)
        if let historyData = defaults.data(forKey: "activityHistory") {
            let historyDict = try JSONDecoder().decode([String: Bool].self, from: historyData)
            
            for (dateString, isCompleted) in historyDict {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = .current
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                guard let date = formatter.date(from: dateString), formatter.string(from: date) == dateString else {
                    throw PersistenceError.invalidMigration
                }
                do {
                    let stat = DailyStat(
                        date: date,
                        solvedCount: isCompleted ? settings.dailyGoal : 0,
                        goalCompleted: isCompleted,
                        srsCleared: false // SRS появился только в новой версии
                    )
                    context.insert(stat)
                }
            }
            print("📅 Мигрировано дней активности: \(historyDict.count)")
        }
        
        // 3. Достижения
        if let achievementsData = defaults.data(forKey: "achievements") {
            let legacyAchievements = try JSONDecoder().decode([LegacyAchievement].self, from: achievementsData)
            
            var unlockedCount = 0
            for legacy in legacyAchievements where legacy.isUnlocked {
                // Ищем новое достижение по совпадению titleKey
                if let newAchievement = AchievementsCatalog.all.first(where: { $0.titleKey == legacy.titleKey }) {
                    settings.unlock(newAchievement.id, on: legacy.unlockedDate ?? .now)
                    unlockedCount += 1
                }
            }
            print("🏆 Мигрировано достижений: \(unlockedCount)")
        }
    }
    
    // MARK: - Helpers
    
    private func fetchOrCreateSettings() throws -> UserSettings {
        let predicate = #Predicate<UserSettings> { $0.id == "singleton" }
        let descriptor = FetchDescriptor<UserSettings>(predicate: predicate)
        
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        
        let newSettings = UserSettings()
        context.insert(newSettings)
        return newSettings
    }
    
    private var legacyFileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("english_words_data.json")
    }
}

// MARK: - Legacy Models (для парсинга старого JSON)

private struct LegacyCardsGroup: Codable {
    let name: String
    let cards: LegacyCards
}

private struct LegacyCards: Codable {
    let cardsArr: [LegacyCard]
}

private struct LegacyCard: Codable {
    let id: UUID
    let originWord: String
    let translatedWord: String
    let groups: [String]
    let dateAdded: Date
    let correctCount: Int
    let wrongCount: Int
}

private struct LegacyAchievement: Codable {
    let titleKey: String
    let isUnlocked: Bool
    let unlockedDate: Date?
}
