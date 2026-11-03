import Foundation
import SwiftData
import Testing
@testable import English_Words

@Suite("Безопасная миграция и повторное открытие базы")
@MainActor
struct MigrationSafetyTests {
    private func legacyJSON(id: UUID) throws -> Data {
        try JSONSerialization.data(withJSONObject: [[
            "name": "Group",
            "cards": ["cardsArr": [[
                "id": id.uuidString, "originWord": "word", "translatedWord": "слово",
                "groups": ["Group"], "dateAdded": "2026-01-01T12:00:00Z", "correctCount": 2, "wrongCount": 1
            ]]]
        ]])
    }

    @Test("Сбой миграции откатывает вставки; повтор и перезапуск не дублируют данные")
    func migrationFailureAndRetry() throws {
        let name = "MigrationSafety.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: name)
            try? FileManager.default.removeItem(at: directory)
        }
        let source = directory.appendingPathComponent("legacy.json")
        let id = UUID()
        try legacyJSON(id: id).write(to: source)
        let storeURL = directory.appendingPathComponent("test.store")
        let schema = Schema([Card.self, CardGroup.self, DailyStat.self, UserSettings.self])
        let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        enum Failure: Error { case save }
        try autoreleasepool {
            let container = try ModelContainer(for: schema, configurations: config)
            container.mainContext.autosaveEnabled = false
            var fail = true
            let transaction = PersistenceTransaction(context: container.mainContext, save: {
                if fail { throw Failure.save }
                try $0.save()
            })
            let migrator = JSONToSwiftDataMigrator(context: container.mainContext, defaults: defaults, sourceURL: source, transaction: transaction)
            #expect(throws: Failure.self) { try migrator.migrateIfNeeded() }
            #expect(try container.mainContext.fetchCount(FetchDescriptor<Card>()) == 0)
            #expect(try container.mainContext.fetchCount(FetchDescriptor<CardGroup>()) == 0)
            #expect(!container.mainContext.hasChanges)
            fail = false
            try migrator.migrateIfNeeded()
            try migrator.migrateIfNeeded()
            #expect(try container.mainContext.fetch(FetchDescriptor<Card>()).map(\.id) == [id])
        }
        // Эмулируем сбой до записи старого UserDefaults-флага.
        defaults.removeObject(forKey: "swiftdata_migration_v2_completed")
        // Новый ModelContainer, а не только повторный fetch из того же контекста.
        let reopened = try ModelContainer(for: schema, configurations: config)
        let migrator = JSONToSwiftDataMigrator(context: reopened.mainContext, defaults: defaults, sourceURL: source)
        try migrator.migrateIfNeeded()
        #expect(try reopened.mainContext.fetch(FetchDescriptor<Card>()).map(\.id) == [id])
        #expect(try reopened.mainContext.fetchCount(FetchDescriptor<CardGroup>()) == 1)
        #expect(try reopened.mainContext.fetch(FetchDescriptor<UserSettings>()).first?.legacyMigrationCompleted == true)
    }

    @Test("Повреждённая старая история не помечает миграцию успешной")
    func corruptHistoryCanBeRetried() throws {
        let name = "MigrationHistory.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let container = try TestContainer.makeContainer()
        let missingSource = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defaults.set(Data("invalid JSON".utf8), forKey: "activityHistory")
        let migrator = JSONToSwiftDataMigrator(context: container.mainContext, defaults: defaults, sourceURL: missingSource)
        #expect(throws: (any Error).self) { try migrator.migrateIfNeeded() }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<UserSettings>()) == 0)
        #expect(!defaults.bool(forKey: "swiftdata_migration_v2_completed"))
        defaults.set(try JSONEncoder().encode(["2026-01-01": true]), forKey: "activityHistory")
        try migrator.migrateIfNeeded()
        #expect(try container.mainContext.fetchCount(FetchDescriptor<DailyStat>()) == 1)
        try migrator.migrateIfNeeded()
        #expect(try container.mainContext.fetchCount(FetchDescriptor<DailyStat>()) == 1)
    }

    @Test("Сбой сохранения восстановления не меняет базу после её повторного открытия")
    func failedRestoreOnDisk() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("RestoreSafety.\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema([Card.self, CardGroup.self, DailyStat.self, UserSettings.self])
        let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("test.store"), cloudKitDatabase: .none)
        enum Failure: Error { case save }
        try autoreleasepool {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = container.mainContext
            context.autosaveEnabled = false
            let card = Card(origin: "old", translated: "старое")
            context.insert(card)
            context.insert(UserSettings())
            try context.save()
            let source = try TestContainer.makeContainer()
            source.mainContext.insert(Card(origin: "new", translated: "новое"))
            source.mainContext.insert(UserSettings())
            try source.mainContext.save()
            let backup = try BackupService.createBackup(context: source.mainContext)
            let transaction = PersistenceTransaction(context: context, save: { _ in throw Failure.save })
            #expect(throws: Failure.self) { try BackupService.restoreBackup(from: backup, context: context, transaction: transaction) }
            #expect(!context.hasChanges)
        }
        let reopened = try ModelContainer(for: schema, configurations: config)
        #expect(try reopened.mainContext.fetch(FetchDescriptor<Card>()).map(\.originWord) == ["old"])
    }
}

extension MigrationSafetyTests {
    @Test("Старая SwiftData-база открывается с новыми optional-полями без потери данных")
    func existingSchemaUpgrade() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SchemaUpgrade.\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let oldSchema = Schema([Card.self, CardGroup.self, PreSafetySchema.DailyStat.self, PreSafetySchema.UserSettings.self])
        let cardID = try autoreleasepool {
            let oldContainer = try ModelContainer(for: oldSchema, configurations: ModelConfiguration(schema: oldSchema, url: url, cloudKitDatabase: .none))
            let context = oldContainer.mainContext
            context.autosaveEnabled = false
            let settings = PreSafetySchema.UserSettings()
            settings.dailyGoal = 35
            settings.totalSolved = 123
            settings.unlock("cards_10", on: Date(timeIntervalSince1970: 1_700_000_000))
            context.insert(settings)
            context.insert(PreSafetySchema.DailyStat(date: .now, dateKey: DailyStat.makeKey(for: .now), solvedCount: 3))
            let card = Card(origin: "before upgrade", translated: "до обновления")
            card.correctCount = 7
            context.insert(card)
            let group = CardGroup(name: "Keep group")
            context.insert(group)
            card.groups = [group]
            try context.save()
            return card.id
        }
        let newSchema = Schema([Card.self, CardGroup.self, DailyStat.self, UserSettings.self])
        let container = try ModelContainer(for: newSchema, configurations: ModelConfiguration(schema: newSchema, url: url, cloudKitDatabase: .none))
        let settings = try #require(container.mainContext.fetch(FetchDescriptor<UserSettings>()).first)
        #expect(settings.dailyGoal == 35)
        #expect(settings.totalSolved == 123)
        #expect(settings.unlockedAchievementIDs == ["cards_10"])
        #expect(settings.solveSessionsData == nil)
        #expect(settings.legacyMigrationCompleted == nil)
        let stat = try #require(container.mainContext.fetch(FetchDescriptor<DailyStat>()).first)
        #expect(stat.solvedCount == 3)
        #expect(stat.srsNewCardsIntroduced == 0)
        #expect(stat.srsReviewCount == 0)
        #expect(stat.srsNextDueDayKey == nil)
        let card = try #require(container.mainContext.fetch(FetchDescriptor<Card>()).first)
        #expect(card.id == cardID)
        #expect(card.correctCount == 7)
        #expect(card.groups.first?.name == "Keep group")
    }

    @Test("Зафиксированный ответ и очередь восстанавливаются новым ModelContainer")
    func answerAndQueueSurviveReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("AnswerReopen.\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let name = "AnswerReopen.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let schema = Schema([Card.self, CardGroup.self, DailyStat.self, UserSettings.self])
        let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("test.store"), cloudKitDatabase: .none)
        let answeredID = try autoreleasepool {
            let container = try ModelContainer(for: schema, configurations: config)
            let app = try AppContainer.live(container: container, defaults: defaults, integrateSystemServices: false)
            _ = try app.cardRepository.create(origin: "one", translated: "один", groups: [])
            _ = try app.cardRepository.create(origin: "two", translated: "два", groups: [])
            let session = try app.solveSessionCoordinator.currentSession(for: .srs)
            let id = try #require(session.currentCardID)
            let fetchedCard = try app.cardRepository.fetch(id: id)
            let card = try #require(fetchedCard)
            _ = try app.answerRecorder.record(card: card, session: session, correct: true, quality: .remembered)
            return id
        }
        let reopened = try ModelContainer(for: schema, configurations: config)
        let app = try AppContainer.live(container: reopened, defaults: defaults, integrateSystemServices: false)
        let session = try app.solveSessionCoordinator.currentSession(for: .srs)
        #expect(session.successIDs == [answeredID])
        #expect(session.unsolvedIDs.count == 1)
        #expect(session.currentCardID != answeredID)
        #expect(try app.cardRepository.fetch(id: answeredID)?.correctCount == 1)
        #expect(try app.statsRepository.settings().totalSolved == 1)
        #expect(try app.statsRepository.activity(for: .now)?.srsNewCardsIntroduced == 1)
        #expect(try app.statsRepository.activity(for: .now)?.srsReviewCount == 1)
        #expect(session.srsQualityCounts?[String(SRSQuality.remembered.rawValue)] == 1)
    }
}
