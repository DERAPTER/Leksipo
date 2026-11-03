import Foundation
import SwiftData
import Testing
@testable import English_Words

@MainActor
private final class LanguageFixture {
    let container: ModelContainer
    let transaction: PersistenceTransaction
    let cards: SwiftDataCardRepository
    let groups: SwiftDataGroupRepository
    let stats: SwiftDataStatsRepository
    let defaults: UserDefaults
    let suite = "StudyLanguageTests.\(UUID())"

    init() throws {
        container = try TestContainer.makeContainer()
        container.mainContext.autosaveEnabled = false
        defaults = try #require(UserDefaults(suiteName: suite))
        let control = LanguageSaveControl()
        transaction = PersistenceTransaction(context: container.mainContext, save: { context in
            if control.fail { throw CocoaError(.fileWriteUnknown) }
            try context.save()
        })
        self.control = control
        cards = SwiftDataCardRepository(context: container.mainContext, transaction: transaction, defaults: defaults)
        groups = SwiftDataGroupRepository(context: container.mainContext, transaction: transaction)
        stats = SwiftDataStatsRepository(context: container.mainContext, transaction: transaction)
        _ = try stats.settings()
    }

    let control: LanguageSaveControl
    deinit { UserDefaults.standard.removePersistentDomain(forName: suite) }

    func pair(_ learning: String = "fr", _ translation: String = "ru") throws -> StudyLanguagePair {
        StudyLanguagePair(learning: try #require(StudyLanguage(code: learning)),
                          translation: try #require(StudyLanguage(code: translation)))
    }

    func importer() -> ImportDataViewModel {
        ImportDataViewModel(cardRepository: cards, groupRepository: groups, transaction: transaction, onComplete: {})
    }

    func card(in group: CardGroup? = nil, pair: StudyLanguagePair? = nil) throws -> Card {
        try cards.create(origin: "chat", translated: "кот", originDescription: "", translatedDescription: "",
                         groups: group.map { [$0] } ?? [], languagePair: pair)
    }
}

@MainActor
private final class LanguageSaveControl { var fail = false }

@Suite("Языки обучения")
@MainActor
struct StudyLanguageTests {
    @Test("Новая настройка не меняет языки прежних карточек, групп и карточек без групп")
    func defaultsApplyOnlyToNewData() throws {
        let f = try LanguageFixture()
        let old = try f.card()
        let oldGroup = try f.groups.create(name: "Old")
        let pair = try f.pair()
        try f.stats.updateStudyLanguages(pair)
        let newGroup = try f.groups.create(name: "New")
        let fresh = try f.card()
        #expect(old.languagePair == .legacy)
        #expect(oldGroup.languagePair == .legacy)
        #expect(newGroup.languagePair == pair)
        #expect(fresh.languagePair == pair)
        let cardInOldGroup = try f.card(in: oldGroup)
        #expect(cardInOldGroup.languagePair == .legacy)
    }

    @Test("Одинаковые тексты разных языков не дубликаты")
    func duplicateIdentityIncludesBothLanguages() throws {
        let f = try LanguageFixture()
        let french = try f.pair()
        _ = try f.card(pair: french)
        #expect(try f.cards.exists(origin: " CHAT ", translated: "КОТ", excluding: nil, languagePair: french))
        #expect(try !f.cards.exists(origin: "chat", translated: "кот", excluding: nil, languagePair: .legacy))
        #expect(try !f.cards.exists(origin: "chat", translated: "кот", excluding: nil, languagePair: f.pair("fr", "de")))
    }

    @Test("Связи разных языков запрещены в create, update и addCard")
    func incompatibleMembershipIsRejected() throws {
        let f = try LanguageFixture()
        let english = try f.groups.create(name: "English")
        let french = try f.groups.create(name: "French", languagePair: f.pair())
        let card = try f.card(in: english)
        #expect(throws: StudyLanguageError.self) { try f.groups.addCard(card, to: french) }
        #expect(throws: StudyLanguageError.self) {
            try f.cards.create(origin: "x", translated: "y", groups: [english, french])
        }
        #expect(throws: StudyLanguageError.self) {
            try f.cards.update(card, origin: "x", translated: "y", groups: [french])
        }
        #expect(card.groups.map(\.id) == [english.id])
        #expect(card.originWord == "chat")
        #expect(!f.container.mainContext.hasChanges)
    }

    @Test("Смена языка группы сохраняет UUID, тексты и прогресс")
    func groupCorrectionPreservesProgress() throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "French")
        let card = try f.card(in: group)
        try f.cards.recordSRSReview(card, quality: 4, on: .now)
        let id = card.id, next = card.nextReviewDate
        let pair = try f.pair()
        let editor = EditGroupViewModel(group: group, groupRepository: f.groups)
        editor.editedLanguagePair = pair
        #expect(!editor.save())
        #expect(editor.showLanguageConfirmation)
        #expect(card.languagePair == .legacy)
        #expect(editor.save(confirmLanguageChange: true))
        #expect(card.languagePair == pair)
        #expect(card.id == id && card.correctCount == 1 && card.nextReviewDate == next)
        #expect(group.languagePair == pair)
    }

    @Test("Общая карточка не меняет язык в другой группе")
    func sharedCardBlocksGroupCorrection() throws {
        let f = try LanguageFixture()
        let first = try f.groups.create(name: "One"), second = try f.groups.create(name: "Two")
        let card = try f.card(in: first)
        try f.groups.addCard(card, to: second)
        #expect(throws: StudyLanguageError.self) { try f.groups.update(first, name: "Renamed", languagePair: f.pair()) }
        #expect(first.name == "One" && first.languagePair == .legacy && card.languagePair == .legacy)
        #expect(card.groups.count == 2)
    }

    @Test("Сбой save откатывает языки группы, карточки и настроек")
    func languageChangesRollback() throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "Old")
        let card = try f.card(in: group)
        f.control.fail = true
        #expect(throws: (any Error).self) { try f.groups.update(group, name: "New", languagePair: f.pair()) }
        #expect(throws: (any Error).self) { try f.stats.updateStudyLanguages(f.pair()) }
        #expect(group.name == "Old" && group.languagePair == .legacy && card.languagePair == .legacy)
        #expect(try f.stats.settings().languagePair == .legacy)
        #expect(!f.container.mainContext.hasChanges)
        let fresh = ModelContext(f.container)
        #expect(try fresh.fetch(FetchDescriptor<Card>()).first?.languagePair == .legacy)
    }

    @Test("Копия карточки другой языковой пары получает новый прогресс")
    func incompatibleCardCopy() throws {
        let f = try LanguageFixture()
        let french = try f.groups.create(name: "French", languagePair: f.pair())
        let original = try f.card()
        try f.cards.recordAnswer(original, correct: true)
        let achievements = AchievementsService(statsRepository: f.stats, cardRepository: f.cards, groupRepository: f.groups)
        let editor = AddCardViewModel(targetGroup: french, cardRepository: f.cards,
                                      groupRepository: f.groups, achievementsService: achievements)
        editor.onAppear()
        editor.toggleCardSelection(original)
        #expect(editor.showLanguageCopyConfirmation)
        #expect(editor.selectedCardIDs.isEmpty)
        editor.prepareLanguageCopy()
        #expect(editor.saveNewCard())
        let copy = try #require(f.cards.fetch(inGroup: french.id).first)
        #expect(copy.id != original.id && copy.languagePair == french.languagePair)
        #expect(copy.correctCount == 0 && copy.lastReviewDate == nil)
        #expect(original.languagePair == .legacy && original.correctCount == 1)
    }

    @Test("Изменение языков карточки учитывает дубликаты новой пары")
    func editChecksLanguages() throws {
        let f = try LanguageFixture()
        let card = try f.card()
        _ = try f.card(pair: f.pair())
        let editor = EditCardViewModel(card: card, cardRepository: f.cards, groupRepository: f.groups)
        editor.onAppear()
        editor.editedLanguagePair = try f.pair()
        #expect(editor.hasChanges)
        #expect(!editor.save() && editor.showDuplicateAlert)
        #expect(card.languagePair == .legacy)
    }

    @Test("Импорт разных языков сохраняет отдельные карточки, одинаковый язык объединяет")
    func multilingualImport() throws {
        let f = try LanguageFixture(), importer = f.importer()
        let json = """
        [
          {"name":"French","learningLanguageCode":"fr","translationLanguageCode":"ru","cards":[{"origin":"chat","translated":"кот"}]},
          {"name":"German","learningLanguageCode":"de","translationLanguageCode":"ru","cards":[{"origin":"chat","translated":"кот"}]},
          {"name":"More French","learningLanguageCode":"fr","translationLanguageCode":"ru","cards":[{"origin":"CHAT","translated":"КОТ"}]}
        ]
        """
        importer.startImport(from: json)
        #expect(importer.showDuplicateAlert && importer.errorMessage == nil)
        #expect(try f.cards.totalCount() == 0)
        importer.confirmImportWithDuplicates()
        #expect(importer.showSuccessAlert)
        #expect(try f.cards.totalCount() == 2)
        let french = try #require(f.cards.fetchAll().first { $0.languagePair.learning.code == "fr" })
        #expect(french.groups.count == 2)
    }

    @Test("Старый JSON использует выбранную пару, изменение выбора отменяет старое подтверждение")
    func legacyImportDefaults() throws {
        let f = try LanguageFixture(), importer = f.importer()
        importer.languagePair = try f.pair()
        let json = """
        [{"name":"Legacy","cards":[{"origin":"chat","translated":"кот"}]}]
        """
        importer.startImport(from: json)
        importer.languagePair = try f.pair("de")
        importer.confirmImportWithDuplicates()
        #expect(try f.cards.totalCount() == 0)
        importer.startImport(from: json)
        importer.confirmImportWithDuplicates()
        #expect(try f.cards.fetchAll().first?.languagePair == f.pair("de"))
    }

    @Test("Неизвестные языки и конфликт имени группы отклоняются до записи", arguments: ["xx-invalid", "de"])
    func invalidImportIsAtomic(code: String) throws {
        let f = try LanguageFixture(), importer = f.importer()
        _ = try f.groups.create(name: "Existing")
        importer.startImport(from: """
        [{"name":"New","cards":[{"origin":"a","translated":"б"}]},
         {"name":"Existing","learningLanguageCode":"\(code)","cards":[{"origin":"chat","translated":"кот"}]}]
        """)
        #expect(importer.errorMessage != nil && !importer.showDuplicateAlert)
        #expect(try f.cards.totalCount() == 0)
        #expect(try f.groups.userGroupsCount() == 1)
    }

    @Test("Сбой save импорта не оставляет новых групп и карточек")
    func importFailureRollsBackLanguages() throws {
        let f = try LanguageFixture(), importer = f.importer()
        importer.languagePair = try f.pair()
        importer.startImport(from: """
        [{"name":"French","cards":[{"origin":"chat","translated":"кот"}]}]
        """)
        f.control.fail = true
        importer.confirmImportWithDuplicates()
        #expect(importer.errorMessage != nil && !importer.showSuccessAlert)
        #expect(try f.cards.totalCount() == 0 && f.groups.userGroupsCount() == 0)
        #expect(!f.container.mainContext.hasChanges)
    }

    @Test("Промпт и JSON отражают выбранные языки")
    func promptUsesSelectedPair() throws {
        let f = try LanguageFixture(), importer = f.importer()
        importer.languagePair = try f.pair("fr", "de")
        let groups = try JSONDecoder().decode([ImportGroupDTO].self, from: Data(importer.jsonTemplate.utf8))
        #expect(try groups.first?.languages(defaults: .legacy) == importer.languagePair)
        #expect(importer.aiPromptTemplate.contains(importer.languagePair.learning.displayName))
        #expect(importer.aiPromptTemplate.contains(importer.languagePair.translation.displayName))
        #expect(!importer.aiPromptTemplate.contains("%@"))
    }

    @Test("Резервная копия сохраняет языки карточек, групп и настроек")
    func backupRoundTrip() throws {
        let source = try LanguageFixture(), target = try LanguageFixture()
        let pair = try source.pair("fr", "de")
        try source.stats.updateStudyLanguages(pair)
        let group = try source.groups.create(name: "French")
        let original = try source.card(in: group)
        let data = try BackupService.createBackup(context: source.container.mainContext)
        #expect(try BackupService.validatedBackup(from: data).schemaVersion == 2)
        try BackupService.restoreBackup(from: data, context: target.container.mainContext, transaction: target.transaction)
        let card = try #require(target.cards.fetchAll().first)
        #expect(card.id == original.id && card.languagePair == pair)
        #expect(card.groups.first?.languagePair == pair)
        #expect(try target.stats.settings().languagePair == pair)
    }

    @Test("Бэкап без языковых полей восстанавливается с английским и русским")
    func oldBackupDefaults() throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "Old")
        _ = try f.card(in: group)
        let data = try BackupService.createBackup(context: f.container.mainContext)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["schemaVersion"] = 1
        for field in ["cards", "groups"] {
            var items = try #require(json[field] as? [[String: Any]])
            for i in items.indices {
                items[i].removeValue(forKey: "learningLanguageCode")
                items[i].removeValue(forKey: "translationLanguageCode")
            }
            json[field] = items
        }
        var settings = try #require(json["settings"] as? [String: Any])
        settings.removeValue(forKey: "learningLanguageCode")
        settings.removeValue(forKey: "translationLanguageCode")
        json["settings"] = settings
        try f.stats.updateStudyLanguages(f.pair())
        let oldData = try JSONSerialization.data(withJSONObject: json)
        try BackupService.restoreBackup(from: oldData, context: f.container.mainContext, transaction: f.transaction)
        #expect(try f.cards.fetchAll().first?.languagePair == .legacy)
        #expect(try f.groups.fetchUserGroups().first?.languagePair == .legacy)
        #expect(try f.stats.settings().languagePair == .legacy)
    }

    @Test("Бэкап с неизвестным языком или несовместимыми связями отклоняется", arguments: ["unknown", "mismatch", "missing"])
    func invalidBackupLanguages(reason: String) throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "Old")
        _ = try f.card(in: group)
        var json = try #require(JSONSerialization.jsonObject(with: BackupService.createBackup(context: f.container.mainContext)) as? [String: Any])
        var cards = try #require(json["cards"] as? [[String: Any]])
        cards[0]["learningLanguageCode"] = reason == "unknown" ? "not-a-language" : "fr"
        if reason == "missing" {
            cards[0].removeValue(forKey: "learningLanguageCode")
            cards[0].removeValue(forKey: "translationLanguageCode")
        }
        json["cards"] = cards
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: PersistenceError.self) { try BackupService.restoreBackup(from: data, context: f.container.mainContext) }
        #expect(try f.cards.fetchAll().first?.languagePair == .legacy)
    }

    @Test("Выбор голоса не подменяет язык; региональный вариант предпочитается")
    func voiceSelection() throws {
        let french = try #require(StudyLanguage(code: "fr"))
        let regional = try #require(StudyLanguage(code: "fr_CA"))
        #expect(regional.code == "fr-CA")
        #expect(PronunciationService.voiceLanguage(for: french, available: ["en-US", "ru-RU"]) == nil)
        #expect(PronunciationService.voiceLanguage(for: french, available: ["en-US", "fr-FR"]) == "fr-FR")
        #expect(PronunciationService.voiceLanguage(for: regional, available: ["fr-FR", "fr-CA"]) == "fr-CA")
        #expect(StudyLanguage(code: "fr--FR") == nil)
        #expect(StudyLanguage(code: "not-a-language") == nil)
        #expect(StudyLanguage.all.count > 100)
    }

    @Test("Миграция существующей базы сохраняет связи, UUID, статистику и английский → русский")
    func existingStoreMigration() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LanguageMigration.\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let oldSchema = Schema([PreLanguageSchema.Card.self, PreLanguageSchema.CardGroup.self,
                                DailyStat.self, PreLanguageSchema.UserSettings.self])
        let id = try autoreleasepool {
            let container = try ModelContainer(for: oldSchema, configurations: ModelConfiguration(schema: oldSchema, url: url, cloudKitDatabase: .none))
            let context = container.mainContext
            context.autosaveEnabled = false
            let settings = PreLanguageSchema.UserSettings()
            settings.totalSolved = 125
            settings.dailyGoal = 35
            context.insert(settings)
            let group = PreLanguageSchema.CardGroup(name: "Old group")
            context.insert(group)
            let card = PreLanguageSchema.Card(origin: "hello", translated: "привет")
            context.insert(card)
            card.groups = [group]
            card.correctCount = 9
            try context.save()
            return card.id
        }
        let schema = Schema([Card.self, CardGroup.self, DailyStat.self, UserSettings.self])
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        try autoreleasepool {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = container.mainContext
            context.autosaveEnabled = false
            let card = try #require(context.fetch(FetchDescriptor<Card>()).first)
            let settings = try #require(context.fetch(FetchDescriptor<UserSettings>()).first)
            #expect(card.id == id && card.correctCount == 9 && card.languagePair == .legacy)
            #expect(card.learningLanguageCode == nil && card.translationLanguageCode == nil)
            #expect(card.groups.first?.name == "Old group")
            #expect(card.groups.first?.languagePair == .legacy)
            #expect(settings.languagePair == .legacy && settings.totalSolved == 125 && settings.dailyGoal == 35)
            let pair = StudyLanguagePair(learning: try #require(StudyLanguage(code: "fr")), translation: .russian)
            let groups = SwiftDataGroupRepository(context: context)
            try groups.update(try #require(card.groups.first), name: "French", languagePair: pair)
        }
        let reopened = try ModelContainer(for: schema, configurations: configuration)
        let card = try #require(reopened.mainContext.fetch(FetchDescriptor<Card>()).first)
        #expect(card.languagePair.learning.code == "fr" && card.groups.first?.languagePair == card.languagePair)
    }

    @Test("Удаление группы и общая очередь SRS сохраняют языки карточек")
    func mixedSRSAndGroupDeletion() throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "French", languagePair: f.pair())
        let french = try f.card(in: group)
        let german = try f.card(pair: f.pair("de"))
        try f.groups.delete(group)
        let frenchPair = try f.pair()
        #expect(french.groups.isEmpty && french.languagePair == frenchPair)
        let store = SolveSessionStore(defaults: f.defaults, transaction: f.transaction)
        let coordinator = SolveSessionCoordinator(store: store, cardRepository: f.cards, defaults: f.defaults)
        let session = try coordinator.currentSession(for: .srs)
        #expect(Set(session.unsolvedIDs) == [french.id, german.id])
        #expect(Set(try f.cards.fetchDueToday(on: .now, newCardsLimit: 20).map { $0.languagePair.learning.code }) == ["fr", "de"])
    }

    @Test("Сбой восстановления откатывает языки всех существующих моделей")
    func backupLanguageRollback() throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "Old")
        let card = try f.card(in: group)
        let backup = try BackupService.createBackup(context: f.container.mainContext)
        try f.groups.update(group, name: "French", languagePair: f.pair())
        try f.stats.updateStudyLanguages(f.pair("de"))
        f.control.fail = true
        #expect(throws: (any Error).self) {
            try BackupService.restoreBackup(from: backup, context: f.container.mainContext, transaction: f.transaction)
        }
        let frenchPair = try f.pair()
        #expect(card.languagePair == frenchPair && group.languagePair == frenchPair && group.name == "French")
        #expect(try f.stats.settings().languagePair == f.pair("de"))
        #expect(!f.container.mainContext.hasChanges)
    }


    @Test("Исправление языка группы не создаёт дубликаты целевой пары")
    func groupLanguageCollision() throws {
        let f = try LanguageFixture()
        let group = try f.groups.create(name: "Old")
        let original = try f.card(in: group)
        _ = try f.card(pair: f.pair())
        #expect(throws: StudyLanguageError.self) {
            try f.groups.update(group, name: "French", languagePair: f.pair())
        }
        #expect(group.name == "Old" && group.languagePair == .legacy)
        #expect(original.languagePair == .legacy && original.groups.map(\.id) == [group.id])
        #expect(!f.container.mainContext.hasChanges)
    }


    @Test("Карточку можно отделить от прежней группы и сохранить с новой языковой парой")
    func changeCardLanguagesAfterRemovingMembership() throws {
        let f = try LanguageFixture()
        let oldGroup = try f.groups.create(name: "Old")
        let newGroup = try f.groups.create(name: "French", languagePair: f.pair())
        let card = try f.card(in: oldGroup)
        let editor = EditCardViewModel(card: card, cardRepository: f.cards, groupRepository: f.groups)
        editor.onAppear()
        editor.editedLanguagePair = try f.pair()
        editor.refreshAvailableGroups()
        editor.toggleGroup(oldGroup)
        #expect(!editor.availableGroups.contains { $0.id == oldGroup.id })
        #expect(editor.availableGroups.contains { $0.id == newGroup.id })
        editor.toggleGroup(newGroup)
        #expect(editor.save())
        #expect(card.groups.map(\.id) == [newGroup.id])
        #expect(card.languagePair == newGroup.languagePair)
    }

}
