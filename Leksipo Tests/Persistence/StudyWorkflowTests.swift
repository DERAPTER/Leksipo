import Foundation
import SwiftData
import Testing
@testable import English_Words

@MainActor
private final class StudyClock {
    var date: Date
    init(_ date: Date) { self.date = date }
}

@MainActor
private final class WorkflowFixture {
    let container: ModelContainer
    let tx: PersistenceTransaction
    let cards: SwiftDataCardRepository
    let groups: SwiftDataGroupRepository
    let stats: SwiftDataStatsRepository
    let defaults: UserDefaults
    let suite = "StudyWorkflow.\(UUID())"
    let clock: StudyClock
    let calendar: Calendar
    let store: SolveSessionStore
    let coordinator: SolveSessionCoordinator
    let recorder: AnswerRecordingService
    let achievements: AchievementsService

    init(date: Date = .now, calendar: Calendar = StudyDay.calendar) throws {
        container = try TestContainer.makeContainer()
        self.calendar = calendar
        clock = StudyClock(date)
        let clock = self.clock
        defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(2, forKey: "srsNewCardsPerDay")
        tx = PersistenceTransaction(context: container.mainContext)
        cards = SwiftDataCardRepository(context: container.mainContext, transaction: tx, calendar: calendar, defaults: defaults, now: { clock.date })
        groups = SwiftDataGroupRepository(context: container.mainContext, transaction: tx)
        stats = SwiftDataStatsRepository(context: container.mainContext, transaction: tx, calendar: calendar, now: { clock.date })
        _ = try stats.settings()
        store = SolveSessionStore(defaults: defaults, transaction: tx)
        try store.migrateLegacySessions()
        coordinator = SolveSessionCoordinator(store: store, cardRepository: cards, defaults: defaults, now: { clock.date }, calendar: calendar)
        recorder = AnswerRecordingService(transaction: tx, cards: cards, stats: stats, coordinator: coordinator, calendar: calendar)
        achievements = AchievementsService(statsRepository: stats, cardRepository: cards, groupRepository: groups)
    }

    deinit { UserDefaults.standard.removePersistentDomain(forName: suite) }

    @discardableResult
    func card(_ word: String) throws -> Card { try cards.create(origin: word, translated: "перевод", groups: []) }

    func answer(_ session: SolveSession, quality: SRSQuality = .remembered) throws -> SolveSession {
        let id = try #require(session.currentCardID)
        let card = try #require(try cards.fetch(id: id))
        return try recorder.record(card: card, session: session, correct: quality.isCorrect, quality: quality)
    }

    func importer() -> ImportDataViewModel {
        ImportDataViewModel(cardRepository: cards, groupRepository: groups, transaction: tx, achievementsService: achievements, onComplete: {})
    }

    func srsViewModel() -> SRSViewModel {
        SRSViewModel(cardRepository: cards, statsRepository: stats, sessionCoordinator: coordinator, achievementsService: achievements, answerRecorder: recorder)
    }

    func advance(_ days: Int) throws {
        clock.date = try #require(calendar.date(byAdding: .day, value: days, to: clock.date))
    }
}

@Suite("Импорт, учебный день и достижения")
@MainActor
struct StudyWorkflowTests {
    @Test("Повторные группы объединяются после предпросмотра, уникальные слова не теряются")
    func mergeRepeatedGroups() throws {
        let f = try WorkflowFixture()
        let vm = f.importer()
        vm.startImport(from: #"[{"name":" Animals ","cards":[{"origin":" cat ","translated":"кот"}]},{"name":"animals","cards":[{"origin":"dog","translated":"собака"}]}]"#)
        #expect(vm.showDuplicateAlert)
        #expect(try f.cards.totalCount() == 0)
        vm.confirmImportWithDuplicates()
        #expect(vm.showSuccessAlert)
        #expect(try f.groups.userGroupsCount() == 1)
        #expect(try f.cards.totalCount() == 2)
        #expect(try f.groups.fetchUserGroups().first?.cards.count == 2)
        #expect(try f.stats.settings().isUnlocked("group_1"))
    }

    @Test("Повторы связываются с новой группой без копий и перезаписи пояснения")
    func existingAndInFileDuplicates() throws {
        let f = try WorkflowFixture()
        let old = try f.cards.create(origin: "Cat", translated: "Кот", originDescription: "original", translatedDescription: "", groups: [])
        let vm = f.importer()
        let text = #"[{"name":"A","cards":[{"origin":" cat ","translated":" кот ","originDescription":"overwrite"}]},{"name":"B","cards":[{"origin":"CAT","translated":"КОТ"},{"origin":"cat","translated":"кот"}]}]"#
        vm.startImport(from: text)
        vm.confirmImportWithDuplicates()
        #expect(try f.cards.totalCount() == 1)
        #expect(Set(old.groups.map(\.name)) == ["A", "B"])
        #expect(old.originDescription == "original")
        #expect(try f.cards.exists(origin: " CAT ", translated: " кот ", excluding: nil))
        vm.startImport(from: text)
        vm.confirmImportWithDuplicates()
        #expect(try f.cards.totalCount() == 1)
        #expect(old.groups.count == 2)
    }

    @Test("Невалидное поле показывает путь до элемента и не создаёт данные")
    func invalidImportPath() throws {
        let f = try WorkflowFixture()
        let vm = f.importer()
        vm.startImport(from: #"[{"name":"A","cards":[{"origin":"x","translated":" "}]}]"#)
        #expect(vm.errorMessage?.contains("[0].cards[0].translated") == true)
        vm.confirmImportWithDuplicates()
        #expect(try f.cards.totalCount() == 0)
        vm.startImport(from: #"[{"name":"A","cards":[{"origin":"x"}]}]"#)
        #expect(vm.errorMessage?.contains("translated") == true)
    }

    @Test("Ошибка нового файла сбрасывает старый текст и подтверждение", arguments: ["missing", "encoding", "cancel", "empty"])
    func failedFileReplacesOldInput(kind: String) throws {
        let f = try WorkflowFixture()
        let vm = f.importer()
        vm.jsonText = "old"
        vm.startImport(from: #"[{"name":"A","cards":[]}]"#)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("StudyImport-\(UUID())")
        defer { try? FileManager.default.removeItem(at: file) }
        switch kind {
        case "encoding":
            try Data([0xff, 0xfe, 0xfd]).write(to: file)
            vm.handleFileSelection(.success([file]))
        case "cancel": vm.handleFileSelection(.failure(CocoaError(.userCancelled)))
        case "empty": vm.handleFileSelection(.success([]))
        default: vm.handleFileSelection(.success([file]))
        }
        #expect(vm.jsonText.isEmpty)
        #expect(!vm.showDuplicateAlert)
        #expect(vm.errorMessage != nil)
        vm.confirmImportWithDuplicates()
        #expect(try f.groups.userGroupsCount() == 0)
    }

    @Test("Лимит расходуется на первом ответе, переживает новую сессию и новый контекст")
    func dailyLimitSurvivesRestart() throws {
        let f = try WorkflowFixture()
        for i in 0..<5 { try f.card("w\(i)") }
        var session = try f.coordinator.currentSession(for: .srs)
        session = try f.answer(session, quality: .forgot)
        #expect(try f.stats.activity(for: f.clock.date)?.srsNewCardsIntroduced == 1)
        session = try f.answer(session)
        #expect(session.isCompletedWithoutMistakes)
        #expect(try f.cards.dueTodayCount(on: f.clock.date, newCardsLimit: 2) == 0)
        #expect(try f.coordinator.currentSession(for: .srs).unsolvedIDs.isEmpty)
        let reopened = SwiftDataCardRepository(context: ModelContext(f.container), calendar: f.calendar, defaults: f.defaults)
        #expect(try reopened.dueTodayCount(on: f.clock.date, newCardsLimit: 2) == 0)
        try f.advance(1)
        let next = try f.cards.srsOverview(on: f.clock.date, newCardsLimit: 2)
        #expect(next.newCardsAvailable == 2)
        #expect(next.overdueCount == 2)
    }

    @Test("Просрочка идёт первой, новые слова вводятся от старых к новым")
    func orderedQueue() throws {
        let f = try WorkflowFixture()
        let old = try f.card("old")
        try f.advance(1)
        let due = try f.card("due")
        try f.cards.recordSRSReview(due, quality: 4, on: f.clock.date)
        try f.advance(1)
        let fresh = try f.card("fresh")
        let queue = try f.coordinator.currentSession(for: .srs)
        #expect(queue.unsolvedIDs == [due.id, old.id, fresh.id])
    }

    @Test("Новый день пересобирает очередь, старый ответ не записывается")
    func midnightRejectsStaleAnswer() throws {
        let f = try WorkflowFixture()
        let a = try f.card("a")
        try f.card("b")
        var old = try f.coordinator.currentSession(for: .srs)
        old = try f.answer(old)
        try f.advance(3)
        let oldID = try #require(old.currentCardID)
        let oldCard = try #require(try f.cards.fetch(id: oldID))
        #expect(throws: PersistenceError.self) { try f.recorder.record(card: oldCard, session: old, correct: true, quality: .remembered) }
        #expect(oldCard.lastReviewDate == nil)
        let fresh = try f.coordinator.currentSession(for: .srs)
        #expect(fresh.studyDayKey != old.studyDayKey)
        #expect(fresh.unsolvedIDs.contains(a.id))
        #expect(fresh.successIDs.isEmpty)
    }

    @Test("Добавленная во время занятия карточка не даёт преждевременно завершить день")
    func additionsExtendQueue() throws {
        let f = try WorkflowFixture()
        try f.card("a")
        var session = try f.coordinator.currentSession(for: .srs)
        let b = try f.card("b")
        session = try f.answer(session)
        #expect(session.currentCardID == b.id)
        #expect(try f.stats.activity(for: f.clock.date)?.srsCleared == false)
        session = try f.answer(session)
        #expect(session.isCompletedWithoutMistakes)
        #expect(try f.stats.activity(for: f.clock.date)?.srsCleared == true)
    }

    @Test("Снижение лимита отсекает неотвеченную новую карточку, повышение открывает остаток")
    func changedLimit() throws {
        let f = try WorkflowFixture()
        for i in 0..<4 { try f.card("w\(i)") }
        var session = try f.coordinator.currentSession(for: .srs)
        session = try f.answer(session)
        f.defaults.set(1, forKey: "srsNewCardsPerDay")
        #expect(try f.coordinator.currentSession(for: .srs).unsolvedIDs.isEmpty)
        f.defaults.set(3, forKey: "srsNewCardsPerDay")
        #expect(try f.coordinator.currentSession(for: .srs).unsolvedIDs.count == 2)
    }

    @Test("Оценки восстановлены вместе с прогрессом; завершение заполняет прогноз")
    func qualityAndForecastSurviveResume() async throws {
        let f = try WorkflowFixture()
        try f.card("a")
        try f.card("b")
        let first = f.srsViewModel()
        first.onAppear()
        await first.rateCurrentCard(.forgot)
        let resumed = f.srsViewModel()
        resumed.onAppear()
        #expect(resumed.reviewedCount == 1)
        #expect(resumed.qualityCounts[.forgot] == 1)
        await resumed.rateCurrentCard(.remembered)
        #expect(resumed.reviewedCount == 2)
        #expect(resumed.qualityCounts.values.reduce(0, +) == 2)
        #expect(resumed.nextReviewDate != nil)
        #expect(resumed.nextReviewCount == 2)
    }

    @Test("Старая настройка цели больше не меняет результаты дня и не создаёт серию")
    func legacyGoalHasNoEffectOnNewAnswers() throws {
        let f = try WorkflowFixture()
        try f.stats.updateDailyGoal(1)
        _ = try f.stats.recordSolved(on: f.clock.date)
        let previous = f.clock.date
        try f.advance(1)
        try f.stats.updateDailyGoal(2)
        _ = try f.stats.recordSolved(on: f.clock.date)
        #expect(try f.stats.activity(for: previous)?.goalCompleted == false)
        #expect(try f.stats.activity(for: f.clock.date)?.goalCompleted == false)
        #expect(try f.stats.currentStreak(on: f.clock.date) == 0)
        #expect(try f.stats.settings().totalSolved == 2)
    }

    @Test("Пустые SRS-дни засчитываются, пропущенное назначение прерывает серию")
    func emptySRSDaysAndMissedAssignment() throws {
        let f = try WorkflowFixture()
        let next = try #require(f.calendar.date(byAdding: .day, value: 4, to: f.clock.date))
        try f.stats.updateSRSStatus(on: f.clock.date, hasDueCards: false, nextReviewDate: next)
        try f.advance(2)
        #expect(try f.stats.currentSRSStreak(on: f.clock.date) == 3)
        try f.advance(2)
        #expect(try f.stats.currentSRSStreak(on: f.clock.date) == 4)
        try f.advance(1)
        #expect(try f.stats.currentSRSStreak(on: f.clock.date) == 0)
        try f.stats.updateSRSStatus(on: f.clock.date, hasDueCards: false, nextReviewDate: nil)
        #expect(try f.stats.currentSRSStreak(on: f.clock.date) == 1)
    }

    @Test("Новая карточка после пустых дней создаёт обязательство со дня добавления")
    func addingCardEndsEmptyGap() throws {
        let f = try WorkflowFixture()
        try f.stats.updateSRSStatus(on: f.clock.date, hasDueCards: false, nextReviewDate: nil)
        try f.advance(2)
        try f.card("new")
        #expect(try f.stats.currentSRSStreak(on: f.clock.date) == 2)
        try f.advance(1)
        #expect(try f.stats.currentSRSStreak(on: f.clock.date) == 0)
    }

    @Test("История старше года и частичная активность не теряются")
    func fullActivityHistory() throws {
        let f = try WorkflowFixture()
        let old = try #require(f.calendar.date(byAdding: .year, value: -2, to: f.clock.date))
        _ = try f.stats.recordSolved(on: old)
        #expect(try f.stats.isDateActive(old))
        #expect(try f.stats.activity(for: old)?.goalCompleted == false)
        let profile = ProfileViewModel(statsRepository: f.stats, cardRepository: f.cards, groupRepository: f.groups, achievementsService: f.achievements, now: { f.clock.date })
        profile.load()
        #expect(profile.activityHistory.contains { $0.dateKey == StudyDay.key(for: old) })
        #expect(profile.isDateActive(old))
    }

    @Test("Все награды показываются по очереди, старое завершение не стирает новое")
    func achievementQueue() throws {
        let f = try WorkflowFixture()
        for i in 0..<10 { try f.card("w\(i)") }
        _ = try f.groups.create(name: "Group")
        let unlocked = f.achievements.evaluate()
        #expect(unlocked.count == 2)
        let first = try #require(f.achievements.recentlyUnlocked)
        f.achievements.consumeRecentlyUnlocked(id: first.id)
        let second = try #require(f.achievements.recentlyUnlocked)
        #expect(first.id != second.id)
        f.achievements.consumeRecentlyUnlocked(id: first.id)
        #expect(f.achievements.recentlyUnlocked?.id == second.id)
        #expect(f.achievements.evaluate().isEmpty)
        f.achievements.consumeRecentlyUnlocked(id: second.id)
        #expect(f.achievements.recentlyUnlocked == nil)
    }

    @Test("Избранное в SRS и свободной тренировке сразу открывает награду", arguments: [true, false])
    func favouriteAchievement(srs: Bool) throws {
        let f = try WorkflowFixture()
        try f.card("one")
        if srs {
            let vm = f.srsViewModel()
            vm.onAppear()
            vm.toggleFavouriteCurrentCard()
            #expect(vm.errorMessage == nil)
        } else {
            let vm = SolveViewModel(key: .system(.allCards), title: "Test", cardRepository: f.cards,
                                   statsRepository: f.stats, sessionCoordinator: f.coordinator,
                                   achievementsService: f.achievements, answerRecorder: f.recorder)
            vm.onAppear()
            vm.toggleFavouriteCurrentCard()
            #expect(vm.errorMessage == nil)
        }
        #expect(try f.stats.settings().isUnlocked("fav_1"))
    }

    @Test("Старый JSON сессии без новых полей читается")
    func legacySessionJSON() throws {
        let id = UUID()
        let data = Data("{\"groupKeyString\":\"srs\",\"unsolvedIDs\":[\"\(id)\"],\"successIDs\":[],\"failIDs\":[]}".utf8)
        let session = try JSONDecoder().decode(SolveSession.self, from: data)
        #expect(session.unsolvedIDs == [id])
        #expect(session.studyDayKey == nil)
        #expect(session.srsQualityCounts == nil)
    }
}

extension StudyWorkflowTests {
    @Test("DST: день длится 23/25 часов, назначение следующего дня не попадает в очередь", arguments: ["2026-03-08", "2026-11-01"])
    func daylightSavingBoundary(key: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let start = try #require(StudyDay.date(for: key, calendar: calendar))
        let end = StudyDay.end(of: start, calendar: calendar)
        #expect(end.timeIntervalSince(start) == (key.contains("03-08") ? 23 : 25) * 3600)
        let f = try WorkflowFixture(date: start.addingTimeInterval(3600), calendar: calendar)
        let card = try f.card("due tomorrow")
        try f.cards.recordSRSReview(card, quality: 4, on: f.clock.date)
        #expect(card.nextReviewDate == end)
        #expect(try f.cards.dueTodayCount(on: end.addingTimeInterval(-1), newCardsLimit: 0) == 0)
        #expect(try f.cards.dueTodayCount(on: end, newCardsLimit: 0) == 1)
        #expect(try f.stats.activity(for: end.addingTimeInterval(-1))?.srsNewCardsIntroduced == 1)
        #expect(try f.stats.activity(for: end) == nil)
    }

    @Test("Бэкап переносит лимит и историю в другую зону, старые поля остаются совместимы")
    func backupAcrossTimeZones() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let date = try #require(StudyDay.date(for: "2026-03-15", calendar: tokyo))
        let source = try WorkflowFixture(date: date.addingTimeInterval(3600), calendar: tokyo)
        try source.card("one")
        _ = try source.answer(source.coordinator.currentSession(for: .srs))
        let backup = try BackupService.createBackup(context: source.container.mainContext)
        var la = Calendar(identifier: .gregorian)
        la.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let target = try WorkflowFixture(date: source.clock.date, calendar: la)
        try BackupService.restoreBackup(from: backup, context: target.container.mainContext, transaction: target.tx)
        let march15 = try #require(StudyDay.date(for: "2026-03-15", calendar: la))
        #expect(try target.stats.activity(for: march15)?.srsNewCardsIntroduced == 1)
        #expect(try target.stats.activity(for: march15)?.srsReviewCount == 1)
        #expect(try target.stats.activityHistory(monthsBack: -1).map(\.dateKey) == ["2026-03-15"])
        var json = try #require(JSONSerialization.jsonObject(with: backup) as? [String: Any])
        var stats = try #require(json["stats"] as? [[String: Any]])
        for i in stats.indices {
            stats[i].removeValue(forKey: "srsNewCardsIntroduced")
            stats[i].removeValue(forKey: "srsReviewCount")
            stats[i].removeValue(forKey: "srsNextDueDayKey")
        }
        json["stats"] = stats
        try BackupService.restoreBackup(from: JSONSerialization.data(withJSONObject: json), context: target.container.mainContext, transaction: target.tx)
        #expect(try target.stats.activity(for: march15)?.srsNewCardsIntroduced == 0)
    }

    @Test("Сбой ответа откатывает дневной лимит, оценки, прогресс и SRS-статус", arguments: [true, false])
    func answerRollbackIncludesNewFields(correct: Bool) throws {
        let f = try WorkflowFixture()
        let card = try f.card("one")
        let session = try f.coordinator.currentSession(for: .srs)
        let failing = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        let cards = SwiftDataCardRepository(context: f.container.mainContext, transaction: failing)
        let stats = SwiftDataStatsRepository(context: f.container.mainContext, transaction: failing)
        let store = SolveSessionStore(defaults: f.defaults, transaction: failing)
        let coordinator = SolveSessionCoordinator(store: store, cardRepository: cards, defaults: f.defaults)
        let recorder = AnswerRecordingService(transaction: failing, cards: cards, stats: stats, coordinator: coordinator)
        #expect(throws: (any Error).self) { try recorder.record(card: card, session: session, correct: correct, quality: correct ? .remembered : .forgot) }
        #expect(card.lastReviewDate == nil)
        #expect(card.srsRecoveryPending == nil)
        #expect(try f.stats.settings().srsMilestonesRaw == nil)
        #expect(try f.stats.activity(for: f.clock.date) == nil)
        #expect(try f.store.load(for: .srs) == session)
        #expect(!f.container.mainContext.hasChanges)
    }

    @Test("Изменение цели откатывается вместе с флагом дня и серией при ошибке save")
    func goalRollback() throws {
        let f = try WorkflowFixture()
        _ = try f.stats.recordSolved(on: f.clock.date)
        let failing = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        let stats = SwiftDataStatsRepository(context: f.container.mainContext, transaction: failing)
        #expect(throws: (any Error).self) { try stats.updateDailyGoal(1) }
        #expect(try f.stats.settings().dailyGoal == 20)
        #expect(try f.stats.activity(for: f.clock.date)?.goalCompleted == false)
        #expect(try f.stats.currentStreak(on: f.clock.date) == 0)
        #expect(!f.container.mainContext.hasChanges)
    }

    @Test("Импорт при финальном сбое не оставляет новые связи и награды")
    func importRollbackIncludesLinks() throws {
        let f = try WorkflowFixture()
        let card = try f.card("word")
        let failing = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        let cards = SwiftDataCardRepository(context: f.container.mainContext, transaction: failing)
        let groups = SwiftDataGroupRepository(context: f.container.mainContext, transaction: failing)
        let vm = ImportDataViewModel(cardRepository: cards, groupRepository: groups, transaction: failing, achievementsService: f.achievements, onComplete: { Issue.record("Не должно быть успеха") })
        vm.startImport(from: #"[{"name":"Group","cards":[{"origin":"word","translated":"перевод"},{"origin":"new","translated":"новый"}]}]"#)
        vm.confirmImportWithDuplicates()
        #expect(vm.errorMessage != nil)
        #expect(!vm.showSuccessAlert)
        #expect(card.groups.isEmpty)
        #expect(try f.cards.totalCount() == 1)
        #expect(try f.groups.userGroupsCount() == 0)
        #expect(try f.stats.settings().unlockedAchievementIDs.isEmpty)
        #expect(!f.container.mainContext.hasChanges)
    }
}

extension StudyWorkflowTests {
    @Test("Знакомство засчитывает любой первый SRS-ответ, завершение — всю очередь")
    func storyFirstReviewAndClear() throws {
        let f = try WorkflowFixture()
        try f.card("one")
        var session = try f.coordinator.currentSession(for: .srs)
        try f.card("added during session")
        session = try f.answer(session, quality: .forgot)
        #expect(try f.stats.settings().srsMilestonesRaw == SRSMilestone.firstReview.mask)
        session = try f.answer(session)
        #expect(session.isCompletedWithoutMistakes)
        #expect(try f.stats.settings().srsMilestonesRaw == SRSMilestone.firstReview.mask | SRSMilestone.firstClear.mask)
        let awarded = f.achievements.evaluate().map(\.id)
        #expect(awarded.contains(SRSMilestone.firstReview.rawValue))
        #expect(awarded.contains(SRSMilestone.firstClear.rawValue))
        #expect(f.achievements.evaluate().isEmpty)
        let reopened = SwiftDataStatsRepository(context: ModelContext(f.container))
        #expect(try reopened.settings().srsMilestonesRaw == 3)
    }

    @Test("Пустой SRS-день и свободная тренировка не выдают сюжетные награды")
    func storyRequiresSRSAnswer() throws {
        let f = try WorkflowFixture()
        try f.stats.updateSRSStatus(on: f.clock.date, hasDueCards: false, nextReviewDate: nil)
        #expect(try f.stats.settings().srsMilestonesRaw == nil)
        let card = try f.card("one")
        let session = try f.coordinator.currentSession(for: .system(.allCards))
        _ = try f.recorder.record(card: card, session: session, correct: true)
        #expect(try f.stats.settings().srsMilestonesRaw == nil)
        #expect(f.achievements.evaluate().allSatisfy { $0.type != .srsMilestone })
    }

    @Test("Отсроченное воспоминание: фактические дни и правильный ответ", arguments: [6, 7, 29, 30], [true, false])
    func storyRecallThresholds(days: Int, correct: Bool) throws {
        let f = try WorkflowFixture()
        let card = try f.card("one")
        _ = try f.answer(f.coordinator.currentSession(for: .srs))
        try f.advance(days)
        _ = try f.answer(f.coordinator.currentSession(for: .srs), quality: correct ? .remembered : .forgot)
        let raw = try f.stats.settings().srsMilestonesRaw ?? 0
        #expect((raw & SRSMilestone.weekRecall.mask != 0) == (correct && days >= 7))
        #expect((raw & SRSMilestone.monthRecall.mask != 0) == (correct && days >= 30))
        #expect(card.lastReviewDate == f.clock.date)
    }

    @Test("Награда за неделю считает календарные дни через переход на летнее время")
    func storyRecallAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let start = try #require(StudyDay.date(for: "2026-03-07", calendar: calendar))
        let f = try WorkflowFixture(date: start.addingTimeInterval(3600), calendar: calendar)
        try f.card("one")
        _ = try f.answer(f.coordinator.currentSession(for: .srs))
        try f.advance(7)
        #expect(f.clock.date.timeIntervalSince(start.addingTimeInterval(3600)) < 7 * 86400)
        _ = try f.answer(f.coordinator.currentSession(for: .srs))
        #expect((try f.stats.settings().srsMilestonesRaw ?? 0) & SRSMilestone.weekRecall.mask != 0)
    }

    @Test("Приручение: три назначенных успеха после ошибки; новая ошибка сбрасывает счёт")
    func storyRecovery() throws {
        let f = try WorkflowFixture()
        let card = try f.card("one")
        _ = try f.answer(f.coordinator.currentSession(for: .srs), quality: .forgot)
        #expect(card.srsRecoveryPending == true)
        let free = try f.coordinator.currentSession(for: .system(.allCards))
        _ = try f.recorder.record(card: card, session: free, correct: true)
        #expect(card.repetitions == 0)
        for quality: SRSQuality in [.remembered, .forgot, .hard, .remembered, .easy] {
            f.clock.date = try #require(card.nextReviewDate)
            _ = try f.answer(f.coordinator.currentSession(for: .srs), quality: quality)
            let raw = try f.stats.settings().srsMilestonesRaw ?? 0
            #expect((raw & SRSMilestone.recovery.mask != 0) == (card.repetitions == 3))
        }
        #expect(card.srsRecoveryPending == false)
        #expect(f.achievements.evaluate().contains { $0.id == SRSMilestone.recovery.rawValue })
    }

    @Test("Старые ошибки из свободной тренировки не становятся SRS-приручением")
    func storyDoesNotInventPastRecovery() throws {
        let f = try WorkflowFixture()
        let card = try f.card("one")
        try f.cards.recordAnswer(card, correct: false)
        for _ in 0..<3 {
            _ = try f.answer(f.coordinator.currentSession(for: .srs))
            f.clock.date = try #require(card.nextReviewDate)
        }
        #expect(card.srsRecoveryPending == nil)
        #expect((try f.stats.settings().srsMilestonesRaw ?? 0) & SRSMilestone.recovery.mask == 0)
    }

    @Test("Сбой выдачи награды не теряет сохранённое событие и позволяет повтор")
    func storyAwardSaveRetry() throws {
        let f = try WorkflowFixture()
        try f.card("one")
        _ = try f.answer(f.coordinator.currentSession(for: .srs))
        let failing = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        let stats = SwiftDataStatsRepository(context: f.container.mainContext, transaction: failing)
        let awards = AchievementsService(statsRepository: stats, cardRepository: f.cards, groupRepository: f.groups)
        #expect(awards.evaluate().isEmpty)
        #expect(awards.recentlyUnlocked == nil)
        #expect(try f.stats.settings().unlockedAchievementIDs.isEmpty)
        #expect(try f.stats.settings().srsMilestonesRaw == 3)
        #expect(f.achievements.evaluate().contains { $0.id == SRSMilestone.firstReview.rawValue })
    }

    @Test("Бэкап сохраняет сюжетные события и незавершённое приручение")
    func storyBackupRoundTrip() throws {
        let f = try WorkflowFixture()
        let card = try f.card("one")
        _ = try f.answer(f.coordinator.currentSession(for: .srs), quality: .forgot)
        let backup = try BackupService.createBackup(context: f.container.mainContext)
        let target = try WorkflowFixture()
        try BackupService.restoreBackup(from: backup, context: target.container.mainContext, transaction: target.tx)
        #expect(try target.cards.fetch(id: card.id)?.srsRecoveryPending == true)
        #expect(try target.stats.settings().srsMilestonesRaw == 3)

        var json = try #require(JSONSerialization.jsonObject(with: backup) as? [String: Any])
        var cards = try #require(json["cards"] as? [[String: Any]])
        cards[0].removeValue(forKey: "srsRecoveryPending")
        json["cards"] = cards
        var settings = try #require(json["settings"] as? [String: Any])
        settings.removeValue(forKey: "srsMilestonesRaw")
        json["settings"] = settings
        #expect(throws: (any Error).self) {
            try BackupService.restoreBackup(from: JSONSerialization.data(withJSONObject: json), context: target.container.mainContext, transaction: target.tx)
        }
        json["schemaVersion"] = 2
        try BackupService.restoreBackup(from: JSONSerialization.data(withJSONObject: json), context: target.container.mainContext, transaction: target.tx)
        #expect(try target.cards.fetch(id: card.id)?.srsRecoveryPending == nil)
        #expect(try target.stats.settings().srsMilestonesRaw == nil)
        settings["srsMilestonesRaw"] = 32
        json["settings"] = settings
        #expect(throws: (any Error).self) {
            try BackupService.restoreBackup(from: JSONSerialization.data(withJSONObject: json), context: target.container.mainContext, transaction: target.tx)
        }
    }
}

extension StudyWorkflowTests {
    @Test("Первая карточка и избранное оценивают достижения после общего commit")
    func firstCardAchievements() throws {
        let f = try WorkflowFixture()
        for i in 0..<9 { try f.card("existing\(i)") }
        let vm = AddFirstCardViewModel(cards: f.cards, transaction: f.tx, achievements: f.achievements)
        #expect(vm.save(origin: "tenth", translated: "десятая", originDescription: "", translatedDescription: "", group: nil, isFavourite: true))
        #expect(try f.stats.settings().isUnlocked("cards_10"))
        #expect(try f.stats.settings().isUnlocked("fav_1"))
        #expect(!vm.save(origin: " TENTH ", translated: " десятая ", originDescription: "", translatedDescription: "", group: nil, isFavourite: false))
        #expect(try f.cards.totalCount() == 10)
    }

    @Test("Сбой первой карточки не оставляет карточку, избранное или награду")
    func firstCardFailure() throws {
        let f = try WorkflowFixture()
        let failing = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        let cards = SwiftDataCardRepository(context: f.container.mainContext, transaction: failing)
        let vm = AddFirstCardViewModel(cards: cards, transaction: failing, achievements: f.achievements)
        #expect(!vm.save(origin: "first", translated: "первая", originDescription: "", translatedDescription: "", group: nil, isFavourite: true))
        #expect(vm.errorMessage != nil)
        #expect(try f.cards.totalCount() == 0)
        #expect(try f.stats.settings().unlockedAchievementIDs.isEmpty)
        #expect(!f.container.mainContext.hasChanges)
    }
}

extension StudyWorkflowTests {
    @Test("Новая карточка во время занятия загружается на экран без потери ответа")
    func viewModelLoadsAddedCard() async throws {
        let f = try WorkflowFixture()
        try f.card("one")
        let vm = f.srsViewModel()
        vm.onAppear()
        let next = try f.card("two")
        await vm.rateCurrentCard(.remembered)
        #expect(vm.currentCard?.id == next.id)
        #expect(vm.reviewedCount == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test("Ни первая, ни повышенная архивная цель не выдают награды")
    func goalRewardIsOncePerDay() throws {
        let f = try WorkflowFixture()
        try f.stats.updateDailyGoal(1)
        #expect(try !f.stats.recordSolved(on: f.clock.date).goalJustCompleted)
        try f.stats.updateDailyGoal(2)
        #expect(try !f.stats.recordSolved(on: f.clock.date).goalJustCompleted)
        #expect(try f.stats.activity(for: f.clock.date)?.goalCompleted == false)
        #expect(try f.stats.currentStreak(on: f.clock.date) == 0)
    }

    @Test("Изменение текста после предпросмотра отменяет старый импорт")
    func previewInvalidatedByNewText() throws {
        let f = try WorkflowFixture()
        let vm = f.importer()
        vm.startImport(from: #"[{"name":"Old","cards":[]}]"#)
        vm.jsonText = #"[{"name":"New","cards":[]}]"#
        vm.confirmImportWithDuplicates()
        #expect(try f.groups.userGroupsCount() == 0)
        vm.startImport(from: vm.jsonText)
        vm.confirmImportWithDuplicates()
        #expect(try f.groups.fetchUserGroups().map(\.name) == ["New"])
    }

    @Test("SRS-обзор засчитывает пустой день один раз и согласован с очередью")
    func emptyDayOverview() throws {
        let f = try WorkflowFixture()
        let vm = SRSOverviewViewModel(cardRepository: f.cards, statsRepository: f.stats, defaults: f.defaults, now: { f.clock.date })
        vm.load()
        vm.load()
        #expect(vm.srsStreak == 1)
        #expect(vm.isSRSClearedToday)
        #expect(vm.overview?.dueToday == 0)
        try f.advance(3)
        vm.load()
        #expect(vm.srsStreak == 4)
        try f.card("new")
        vm.load()
        #expect(vm.overview?.dueToday == 1)
        #expect(!vm.isSRSClearedToday)
        #expect(vm.srsStreak == 3)
    }
}

extension StudyWorkflowTests {
    @Test("Практика всех трудных слов использует классические ответы и сохраняет расписание SRS")
    func attentionPracticePreservesSRS() async throws {
        let f = try WorkflowFixture()
        let cards = try (0..<8).map { try f.card("hard\($0)") }
        let unrelated = try f.card("ordinary")
        let last = f.clock.date.addingTimeInterval(-14 * 86400)
        let next = f.clock.date.addingTimeInterval(14 * 86400)
        for card in cards {
            card.wrongCount = 3
            card.correctCount = 2
            card.lastReviewDate = last
            card.nextReviewDate = next
            card.intervalDays = 28
            card.repetitions = 3
            card.easeFactor = 2.4
            card.srsRecoveryPending = true
        }
        try f.container.mainContext.save()
        let groupSession = try f.coordinator.currentSession(for: .system(.allCards))
        let srsSession = try f.coordinator.currentSession(for: .srs)
        #expect(srsSession.currentCardID == unrelated.id)
        let key = SolveGroupKey.practice(cards.map(\.id))
        let vm = SolveViewModel(key: key, title: "Practice", cardRepository: f.cards, statsRepository: f.stats,
                               sessionCoordinator: f.coordinator, achievementsService: f.achievements, answerRecorder: f.recorder)
        vm.onAppear()
        #expect(vm.totalProgress == 8)
        for index in cards.indices {
            #expect(vm.currentCard?.id != unrelated.id)
            await vm.commitSwipe(index.isMultiple(of: 2) ? .flyRight : .flyLeft)
            #expect(vm.errorMessage == nil)
        }
        #expect(vm.state == .completedWithMistakes)
        #expect(vm.successCount == 4 && vm.failCount == 4)
        for card in cards {
            #expect(card.lastReviewDate == last && card.nextReviewDate == next)
            #expect(card.intervalDays == 28 && card.repetitions == 3 && card.easeFactor == 2.4)
            #expect(card.srsRecoveryPending == true)
        }
        #expect(try f.stats.settings().srsMilestonesRaw == nil)
        #expect(try f.stats.activity(for: f.clock.date)?.srsReviewCount == 0)
        #expect(try f.store.load(for: .srs) == srsSession)
        #expect(try f.store.load(for: .system(.allCards)) == groupSession)
        vm.restartMistakesFromResult()
        #expect(vm.totalProgress == 4)
        vm.restartFromResult()
        #expect(vm.totalProgress == 8)
    }

    @Test("Подборка фиксируется при запуске; удалённые слова исключаются при возобновлении")
    func practiceKeepsSelection() throws {
        let f = try WorkflowFixture()
        let cards = try (0..<8).map { try f.card("selected\($0)") }
        let key = SolveGroupKey.practice(cards.map(\.id))
        var session = try f.coordinator.currentSession(for: key)
        let firstID = try #require(session.currentCardID)
        let first = try #require(try f.cards.fetch(id: firstID))
        session = try f.recorder.record(card: first, session: session, correct: true)
        let added = try f.card("added later")
        let deletedID = try #require(session.currentCardID)
        let deleted = try #require(try f.cards.fetch(id: deletedID))
        try f.cards.delete(deleted)
        let resumed = try f.coordinator.currentSession(for: key)
        #expect(resumed.totalCount == 7)
        #expect(resumed.successIDs == [first.id])
        #expect(!resumed.unsolvedIDs.contains(added.id))
        let restarted = try f.coordinator.restartAll(for: key)
        #expect(restarted.totalCount == 7)
        #expect(!restarted.unsolvedIDs.contains(added.id))
    }

    @Test("Новая подборка заменяет прежнюю практику, сохраняя очереди групп и SRS")
    func practiceStorageIsIsolated() throws {
        let f = try WorkflowFixture()
        let a = try f.card("a"), b = try f.card("b")
        let group = try f.coordinator.currentSession(for: .system(.allCards))
        let srs = try f.coordinator.currentSession(for: .srs)
        let old = SolveGroupKey.practice([a.id])
        _ = try f.coordinator.currentSession(for: old)
        let key = SolveGroupKey.practice([a.id, b.id])
        let fresh = try f.coordinator.currentSession(for: key)
        #expect(try f.store.load(for: old) == nil)
        #expect(try f.store.load(for: key) == fresh)
        #expect(try f.store.load(for: .system(.allCards)) == group)
        #expect(try f.store.load(for: .srs) == srs)
        let reopened = SolveSessionStore(defaults: f.defaults, transaction: f.tx)
        #expect(try reopened.load(for: key) == fresh)
    }

    @Test("Ошибка сохранения новой практики не удаляет предыдущую подборку")
    func practiceReplacementRollback() throws {
        let f = try WorkflowFixture()
        let a = try f.card("a"), b = try f.card("b")
        let key = SolveGroupKey.practice([a.id])
        let old = try f.coordinator.currentSession(for: key)
        let failing = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        let store = SolveSessionStore(defaults: f.defaults, transaction: failing)
        let replacement = SolveGroupKey.practice([a.id, b.id])
        #expect(throws: (any Error).self) {
            try store.save(SolveSession(groupKey: replacement, cardIDs: [a.id, b.id]), for: replacement)
        }
        #expect(try f.store.load(for: key) == old)
        #expect(try f.store.load(for: replacement) == nil)
    }
}
