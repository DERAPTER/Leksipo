import Foundation
import SwiftData
import Testing
@testable import English_Words

private enum InjectedFailure: Error { case save }

@MainActor
private final class SaveControl {
    var shouldFail = false
    var saves = 0
    func save(_ context: ModelContext) throws {
        saves += 1
        if shouldFail { throw InjectedFailure.save }
        try context.save()
    }
}

@MainActor
private final class SafetyFixture {
    let container: ModelContainer
    let context: ModelContext
    let control = SaveControl()
    let transaction: PersistenceTransaction
    let cards: SwiftDataCardRepository
    let groups: SwiftDataGroupRepository
    let stats: SwiftDataStatsRepository
    let store: SolveSessionStore
    let coordinator: SolveSessionCoordinator
    let achievements: AchievementsService
    let recorder: AnswerRecordingService
    let defaults: UserDefaults
    let suiteName: String

    init(container supplied: ModelContainer? = nil) throws {
        container = try supplied ?? TestContainer.makeContainer()
        context = container.mainContext
        context.autosaveEnabled = false
        let control = self.control
        transaction = PersistenceTransaction(context: context, save: { try control.save($0) })
        cards = SwiftDataCardRepository(context: context, transaction: transaction)
        groups = SwiftDataGroupRepository(context: context, transaction: transaction)
        stats = SwiftDataStatsRepository(context: context, transaction: transaction)
        suiteName = "DataSafetyTests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        store = SolveSessionStore(defaults: defaults, transaction: transaction)
        _ = try stats.settings()
        try store.migrateLegacySessions()
        coordinator = SolveSessionCoordinator(store: store, cardRepository: cards, defaults: defaults)
        achievements = AchievementsService(statsRepository: stats, cardRepository: cards, groupRepository: groups)
        recorder = AnswerRecordingService(transaction: transaction, cards: cards, stats: stats, coordinator: coordinator)
    }

    deinit { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    func card(_ word: String = "word") throws -> Card {
        try cards.create(origin: word, translated: "перевод", groups: [])
    }

    func srsViewModel() -> SRSViewModel {
        SRSViewModel(cardRepository: cards, statsRepository: stats, sessionCoordinator: coordinator,
                     achievementsService: achievements, answerRecorder: recorder)
    }

    func solveViewModel() -> SolveViewModel {
        SolveViewModel(key: .system(.allCards), title: "Test", cardRepository: cards,
                       statsRepository: stats, sessionCoordinator: coordinator,
                       achievementsService: achievements, answerRecorder: recorder)
    }

    func settingsViewModel(onRestore: @escaping () -> Void = {}) -> SettingsViewModel {
        SettingsViewModel(cardRepository: cards, groupRepository: groups, statsRepository: stats,
                          solveSessionStore: store, transaction: transaction, onRestore: onRestore)
    }

    func backup() throws -> Data { try BackupService.createBackup(context: context) }
}

@Suite("Сохранность данных и ответов")
@MainActor
struct DataSafetyTests {
    @Test("Сбой восстановления сохраняет прежние карточки, связи, статистику и очередь")
    func restoreRollsBackEverything() throws {
        let f = try SafetyFixture()
        let old = try f.card("old")
        let group = try f.groups.create(name: "Old group")
        try f.groups.addCard(old, to: group)
        _ = try f.stats.recordSolved(on: .now)
        let session = try f.coordinator.currentSession(for: .srs)
        let original = try f.backup()
        let source = try SafetyFixture()
        _ = try source.card("replacement")
        let replacement = try source.backup()
        f.control.shouldFail = true
        #expect(throws: InjectedFailure.self) {
            try BackupService.restoreBackup(from: replacement, context: f.context, transaction: f.transaction)
        }
        #expect(!f.context.hasChanges)
        #expect(try f.cards.fetchAll().map(\.id) == [old.id])
        #expect(old.groups.map(\.id) == [group.id])
        #expect(try f.stats.settings().totalSolved == 1)
        #expect(try f.store.load(for: .srs) == session)
        #expect(try BackupService.validatedBackup(from: original).cards.count == 1)
        f.control.shouldFail = false
        try BackupService.restoreBackup(from: replacement, context: f.context, transaction: f.transaction)
        #expect(try f.cards.fetchAll().map(\.originWord) == ["replacement"])
        #expect(try f.store.allSessionKeys().isEmpty)
        let fresh = ModelContext(f.container)
        #expect(try fresh.fetch(FetchDescriptor<Card>()).map(\.originWord) == ["replacement"])
    }

    @Test("Восстановление совпадающих UUID обновляет сущности без дублей и теряемых связей")
    func restoreSameIDs() throws {
        let f = try SafetyFixture()
        let card = try f.card()
        let group = try f.groups.create(name: "Group")
        try f.groups.addCard(card, to: group)
        let backup = try f.backup()
        try f.cards.update(card, origin: "changed", translated: "changed", groups: [])
        try BackupService.restoreBackup(from: backup, context: f.context, transaction: f.transaction)
        #expect(try f.cards.totalCount() == 1)
        #expect(try f.groups.userGroupsCount() == 1)
        #expect(card.originWord == "word")
        #expect(card.groups.map(\.id) == [group.id])
    }

    @Test("Невалидный бэкап отклоняется до записи", arguments: ["future", "duplicate", "missingGroup", "negative", "invalidDate", "invalidSRS"])
    func rejectsInvalidBackup(kind: String) throws {
        let f = try SafetyFixture()
        let card = try f.card()
        var json = try #require(JSONSerialization.jsonObject(with: f.backup()) as? [String: Any])
        var cards = try #require(json["cards"] as? [[String: Any]])
        switch kind {
        case "future": json["schemaVersion"] = 999
        case "duplicate": cards.append(cards[0])
        case "missingGroup": cards[0]["groupIDs"] = [UUID().uuidString]
        case "negative": cards[0]["correctCount"] = -1
        case "invalidSRS": cards[0]["intervalDays"] = Int.max
        default: cards[0]["dateAdded"] = "not-a-date"
        }
        json["cards"] = cards
        let corrupt = try JSONSerialization.data(withJSONObject: json)
        let saveCount = f.control.saves
        #expect(throws: (any Error).self) {
            try BackupService.restoreBackup(from: corrupt, context: f.context, transaction: f.transaction)
        }
        #expect(f.control.saves == saveCount)
        #expect(try f.cards.fetchAll().map(\.id) == [card.id])
        #expect(!f.context.hasChanges)
    }

    @Test("Старый бэкап 2.9.0 читается; неизвестный формат без schemaVersion отклоняется")
    func legacyBackupCompatibility() throws {
        let f = try SafetyFixture()
        _ = try f.card()
        var json = try #require(JSONSerialization.jsonObject(with: f.backup()) as? [String: Any])
        json.removeValue(forKey: "schemaVersion")
        json["version"] = "2.9.0"
        let legacy = try JSONSerialization.data(withJSONObject: json)
        #expect(try BackupService.validatedBackup(from: legacy).cards.count == 1)
        json["version"] = "99.0"
        let unknown = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: PersistenceError.self) { try BackupService.validatedBackup(from: unknown) }
    }

    @Test("Чужие несохранённые изменения не откатываются и не фиксируются")
    func preservesUnrelatedPendingChanges() throws {
        let f = try SafetyFixture()
        let card = try f.card()
        let backup = try f.backup()
        card.originWord = "draft"
        #expect(throws: PersistenceError.self) {
            try BackupService.restoreBackup(from: backup, context: f.context, transaction: f.transaction)
        }
        #expect(card.originWord == "draft")
        #expect(f.context.hasChanges)
        let fresh = ModelContext(f.container)
        #expect(try fresh.fetch(FetchDescriptor<Card>()).first?.originWord == "word")
        f.context.rollback()
    }

    @Test("Ошибка отдельного изменения карточки не попадает в последующее сохранение")
    func repositoryRollback() throws {
        let f = try SafetyFixture()
        let card = try f.card()
        f.control.shouldFail = true
        #expect(throws: (any Error).self) { try f.cards.toggleFavourite(card) }
        #expect(!card.isFavourite)
        #expect(!f.context.hasChanges)
        f.control.shouldFail = false
        _ = try f.groups.create(name: "Other change")
        #expect(try ModelContext(f.container).fetch(FetchDescriptor<Card>()).first?.isFavourite == false)
    }

    @Test("Ошибка финального save откатывает карточку, статистику, SRS-день и очередь", arguments: [true, false])
    func answerFailureIsAtomic(srs: Bool) throws {
        let f = try SafetyFixture()
        let card = try f.card()
        let key: SolveGroupKey = srs ? .srs : .system(.allCards)
        let session = try f.coordinator.currentSession(for: key)
        f.control.shouldFail = true
        #expect(throws: (any Error).self) {
            try f.recorder.record(card: card, session: session, correct: true, quality: srs ? .remembered : nil)
        }
        #expect(card.correctCount == 0)
        #expect(card.lastReviewDate == nil)
        #expect(try f.stats.settings().totalSolved == 0)
        #expect(try f.stats.activity(for: .now) == nil)
        #expect(try f.store.load(for: key) == session)
        #expect(!f.context.hasChanges)
        f.control.shouldFail = false
        _ = try f.recorder.record(card: card, session: session, correct: true, quality: srs ? .remembered : nil)
        #expect(card.correctCount == 1)
        #expect(try f.stats.settings().totalSolved == 1)
        #expect(try f.store.load(for: key) == nil)
        #expect(try f.stats.activity(for: .now)?.srsCleared == srs)
        // Повтор уже зафиксированного ответа после сбоя UI тоже не записывается.
        #expect(throws: PersistenceError.self) {
            try f.recorder.record(card: card, session: session, correct: true, quality: srs ? .remembered : nil)
        }
        #expect(card.correctCount == 1)
    }

    @Test("Двойное нажатие SRS принимает только один ответ")
    func srsDoubleTap() async throws {
        let f = try SafetyFixture()
        _ = try f.card("one")
        _ = try f.card("two")
        let vm = f.srsViewModel()
        vm.onAppear()
        let first = try #require(vm.currentCard)
        let firstAnswer = Task { await vm.rateCurrentCard(.remembered) }
        await Task.yield()
        await vm.rateCurrentCard(.easy)
        await firstAnswer.value
        #expect(first.correctCount == 1)
        #expect(vm.reviewedCount == 1)
        #expect(vm.qualityCounts.values.reduce(0, +) == 1)
        #expect(vm.currentCard?.id != first.id)
    }

    @Test("Повторный свайп принимает только один ответ")
    func doubleSwipe() async throws {
        let f = try SafetyFixture()
        _ = try f.card("one")
        _ = try f.card("two")
        let vm = f.solveViewModel()
        vm.onAppear()
        let first = try #require(vm.currentCard)
        let answer = Task { await vm.commitSwipe(.flyRight) }
        await Task.yield()
        await vm.commitSwipe(.flyLeft)
        await answer.value
        #expect(first.correctCount == 1)
        #expect(first.wrongCount == 0)
        #expect(vm.successCount == 1)
        #expect(vm.failCount == 0)
    }

    @Test("Ошибка ответа остаётся на той же карточке и допускает повтор")
    func viewModelErrorAndRetry() async throws {
        let f = try SafetyFixture()
        let card = try f.card()
        let vm = f.srsViewModel()
        vm.onAppear()
        f.control.shouldFail = true
        await vm.rateCurrentCard(.remembered)
        #expect(vm.errorMessage != nil)
        #expect(vm.currentCard?.id == card.id)
        #expect(vm.reviewedCount == 0)
        #expect(vm.qualityCounts.isEmpty)
        #expect(!vm.isProcessingAnswer)
        f.control.shouldFail = false
        await vm.rateCurrentCard(.remembered)
        #expect(vm.errorMessage == nil)
        #expect(card.correctCount == 1)
        #expect(vm.reviewedCount == 1)
    }

    @Test("Отмена анимации после commit не теряет записанный ответ")
    func cancelAfterCommit() async throws {
        let f = try SafetyFixture()
        _ = try f.card("one")
        _ = try f.card("two")
        let vm = f.srsViewModel()
        vm.onAppear()
        let task = Task { await vm.rateCurrentCard(.remembered) }
        await Task.yield()
        task.cancel()
        await task.value
        #expect(!vm.isProcessingAnswer)
        #expect(vm.reviewedCount == 1)
        #expect(vm.currentCard?.id == vm.session.currentCardID)
        #expect(try f.store.load(for: .srs) == vm.session)
    }

    @Test("SRS продолжает очередь после удаления текущей и будущей карточки")
    func resumeAfterDeletion() throws {
        let f = try SafetyFixture()
        let a = try f.card("one")
        let b = try f.card("two")
        let c = try f.card("three")
        var session = SolveSession(groupKey: .srs, cardIDs: [])
        session.unsolvedIDs = [a.id, b.id, c.id]
        try f.store.save(session, for: .srs)
        try f.cards.delete(a)
        try f.cards.delete(b)
        let vm = f.srsViewModel()
        vm.onAppear()
        #expect(vm.currentCard?.id == c.id)
        #expect(vm.totalProgress == 1)
        try f.cards.delete(c)
        vm.onAppear()
        #expect(vm.totalProgress == 0)
        #expect(try f.store.load(for: .srs) == nil)
    }

    @Test("Импорт при ошибке в середине не оставляет группу и первые карточки")
    func importRollsBackPartialWork() throws {
        let f = try SafetyFixture()
        var completed = false
        let vm = ImportDataViewModel(cardRepository: f.cards, groupRepository: f.groups,
                                     transaction: f.transaction, onComplete: { completed = true })
        vm.startImport(from: #"[{"name":"Group","cards":[{"origin":"valid","translated":"да"},{"origin":" ","translated":"нет"}]}]"#)
        #expect(vm.errorMessage != nil)
        #expect(!completed)
        #expect(!vm.showSuccessAlert)
        #expect(try f.cards.totalCount() == 0)
        #expect(try f.groups.userGroupsCount() == 0)
        #expect(!f.context.hasChanges)
    }

    @Test("Импорт откатывается при финальном save и может быть повторён")
    func importSaveFailureAndRetry() throws {
        let f = try SafetyFixture()
        let vm = ImportDataViewModel(cardRepository: f.cards, groupRepository: f.groups,
                                     transaction: f.transaction, onComplete: {})
        let input = #"[{"name":"Group","cards":[{"origin":"valid","translated":"да"}]}]"#
        f.control.shouldFail = true
        vm.startImport(from: input)
        vm.confirmImportWithDuplicates()
        #expect(try f.cards.totalCount() == 0)
        #expect(try f.groups.userGroupsCount() == 0)
        f.control.shouldFail = false
        vm.startImport(from: input)
        vm.confirmImportWithDuplicates()
        #expect(vm.showSuccessAlert)
        #expect(try f.cards.totalCount() == 1)
    }

    @Test("Удаление всех данных при ошибке оставляет прежние данные и сессию")
    func deleteAllRollback() throws {
        let f = try SafetyFixture()
        let card = try f.card()
        let group = try f.groups.create(name: "Group")
        try f.groups.addCard(card, to: group)
        _ = try f.stats.recordSolved(on: .now)
        let session = try f.coordinator.currentSession(for: .srs)
        let vm = f.settingsViewModel()
        f.control.shouldFail = true
        vm.deleteAllData()
        #expect(vm.errorMessage != nil)
        #expect(try f.cards.totalCount() == 1)
        #expect(try f.groups.userGroupsCount() == 1)
        #expect(try f.stats.settings().totalSolved == 1)
        #expect(try f.store.load(for: .srs) == session)
        #expect(card.groups.map(\.id) == [group.id])
        #expect(group.cards.map(\.id) == [card.id])
        #expect(!f.context.hasChanges)
    }

    @Test("Очередь из UserDefaults переносится однократно и восстанавливается новым store")
    func sessionMigration() throws {
        let container = try TestContainer.makeContainer()
        let tx = PersistenceTransaction(context: container.mainContext)
        let name = "LegacySessionTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let legacy = SolveSessionStore(defaults: defaults)
        let session = SolveSession(groupKey: .srs, cardIDs: [UUID(), UUID()])
        try legacy.save(session, for: .srs)
        let store = SolveSessionStore(defaults: defaults, transaction: tx)
        try store.migrateLegacySessions()
        #expect(try store.load(for: .srs) == session)
        try store.clearAll()
        let reopened = SolveSessionStore(defaults: defaults, transaction: PersistenceTransaction(context: ModelContext(container)))
        try reopened.migrateLegacySessions()
        #expect(try reopened.load(for: .srs) == nil)
    }

    @Test("Ошибка запуска показывает состояние восстановления; повтор не создаёт приложение дважды")
    func startupRetry() throws {
        let container = try TestContainer.makeContainer()
        let fixture = try SafetyFixture()
        var attempts = 0
        var migrations = 0
        let startup = AppStartup(makeContainer: {
            attempts += 1
            if attempts == 1 { throw InjectedFailure.save }
            return container
        }, migrate: { _ in migrations += 1 }, makeApp: { try AppContainer.live(container: $0, defaults: fixture.defaults, integrateSystemServices: false) })
        startup.start()
        #expect(startup.app == nil)
        #expect(startup.errorMessage != nil)
        startup.start()
        #expect(startup.app != nil)
        #expect(startup.errorMessage == nil)
        startup.start()
        #expect(attempts == 2)
        #expect(migrations == 1)
    }
}

extension DataSafetyTests {
    @Test("Неуспешный обычный ответ остаётся в очереди без счётчиков успеха")
    func freePracticeFailureAndRetry() async throws {
        let f = try SafetyFixture()
        let card = try f.card()
        let vm = f.solveViewModel()
        vm.onAppear()
        f.control.shouldFail = true
        await vm.commitSwipe(.flyRight)
        #expect(vm.errorMessage != nil)
        #expect(vm.currentCard?.id == card.id)
        #expect(vm.successCount == 0)
        #expect(card.correctCount == 0)
        f.control.shouldFail = false
        await vm.commitSwipe(.flyRight)
        #expect(card.correctCount == 1)
        #expect(vm.successCount == 1)
    }

    @Test("Ошибка восстановления не вызывает обновление UI; успех очищает очередь до callback")
    func restoreUpdatesOnlyAfterCommit() throws {
        let f = try SafetyFixture()
        _ = try f.card()
        let session = try f.coordinator.currentSession(for: .srs)
        let data = try f.backup()
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("RestoreCallback.\(UUID()).json")
        try data.write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        var callbacks = 0
        let vm = f.settingsViewModel(onRestore: { callbacks += 1 })
        vm.handleImportFile(.success([file]))
        f.control.shouldFail = true
        vm.confirmRestore(context: f.context)
        #expect(callbacks == 0)
        #expect(try f.store.load(for: .srs) == session)
        f.control.shouldFail = false
        vm.confirmRestore(context: f.context)
        #expect(callbacks == 1)
        #expect(try f.store.allSessionKeys().isEmpty)
        // Даже при старой копии UserDefaults восстановление не возвращает прежнюю очередь.
        let restarted = SolveSessionStore(defaults: f.defaults, transaction: f.transaction)
        try restarted.migrateLegacySessions()
        #expect(try restarted.allSessionKeys().isEmpty)
    }

    @Test("Ошибка миграции оставляет экран восстановления; валидный бэкап открывает приложение")
    func startupRecoveryFromBackup() throws {
        let f = try SafetyFixture()
        _ = try f.card()
        let backup = try f.backup()
        let target = try TestContainer.makeContainer()
        let startup = AppStartup(makeContainer: { target }, migrate: { _ in throw InjectedFailure.save },
                                 makeApp: { try AppContainer.live(container: $0, defaults: f.defaults, integrateSystemServices: false) })
        startup.start()
        #expect(startup.app == nil)
        #expect(startup.container != nil)
        #expect(startup.errorMessage != nil)
        startup.restore(backup)
        #expect(startup.app != nil)
        #expect(startup.errorMessage == nil)
        #expect(try startup.app?.cardRepository.totalCount() == 1)
    }

    @Test("Достижения явно сохраняются, не оставляя грязного контекста перед следующей операцией")
    func achievementsAreCommitted() throws {
        let f = try SafetyFixture()
        _ = try f.groups.create(name: "Group")
        _ = f.achievements.evaluate()
        #expect(!f.context.hasChanges)
        #expect(try ModelContext(f.container).fetch(FetchDescriptor<UserSettings>()).first?.unlockedAchievementIDs.contains("group_1") == true)
    }
}


extension DataSafetyTests {
    @Test("Асинхронное открытие базы допускает повтор после ошибки и защищено от повторного входа")
    func asyncStartupRetry() async throws {
        let container = try TestContainer.makeContainer()
        let fixture = try SafetyFixture()
        var attempts = 0
        var migrations = 0
        weak var startup: AppStartup?
        let subject = AppStartup(loadContainer: {
            attempts += 1
            #expect(startup?.isStarting == true)
            #expect(startup?.app == nil)
            await startup?.startAsync()
            if attempts == 1 { throw InjectedFailure.save }
            return container
        }, migrate: { _ in migrations += 1 }, makeApp: {
            try AppContainer.live(container: $0, defaults: fixture.defaults, integrateSystemServices: false)
        })
        startup = subject
        await subject.startAsync()
        #expect(subject.app == nil)
        #expect(subject.errorMessage != nil)
        #expect(!subject.isStarting)
        await subject.startAsync()
        #expect(subject.app != nil)
        #expect(subject.errorMessage == nil)
        await subject.startAsync()
        #expect(attempts == 2)
        #expect(migrations == 1)
    }

    @Test("Отмена асинхронного открытия не запускает миграцию и не показывает ошибку базы")
    func asyncStartupCancellation() async throws {
        let container = try TestContainer.makeContainer()
        let fixture = try SafetyFixture()
        var attempts = 0
        var migrations = 0
        let startup = AppStartup(loadContainer: {
            attempts += 1
            if attempts == 1 { throw CancellationError() }
            return container
        }, migrate: { _ in migrations += 1 }, makeApp: {
            try AppContainer.live(container: $0, defaults: fixture.defaults, integrateSystemServices: false)
        })
        await startup.startAsync()
        #expect(startup.container == nil)
        #expect(startup.app == nil)
        #expect(startup.errorMessage == nil)
        #expect(!startup.isStarting)
        #expect(migrations == 0)
        await startup.startAsync()
        #expect(startup.app != nil)
        #expect(migrations == 1)
    }
}
