import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import English_Words

@MainActor
private final class NotificationProbe: SRSNotificationClient {
    var status: UNAuthorizationStatus = .authorized
    var requests: [String: SRSReminder] = [:]
    var permissionRequests = 0
    var holdAuthorization = false
    var holdAdd = false
    var failAdd = false
    var authorizationWaiter: CheckedContinuation<UNAuthorizationStatus, Never>?
    var addWaiter: CheckedContinuation<Void, Never>?

    func authorization() async -> UNAuthorizationStatus {
        if holdAuthorization { return await withCheckedContinuation { authorizationWaiter = $0 } }
        return status
    }
    func requestPermission() async throws -> Bool { permissionRequests += 1; return status == .authorized }
    func add(_ reminder: SRSReminder) async throws {
        if holdAdd { await withCheckedContinuation { addWaiter = $0 } }
        if failAdd { throw CocoaError(.fileWriteUnknown) }
        requests[reminder.identifier] = reminder
    }
    func remove(identifiers: [String]) { identifiers.forEach { requests.removeValue(forKey: $0) } }
    func releaseAuthorization() { holdAuthorization = false; authorizationWaiter?.resume(returning: status); authorizationWaiter = nil }
    func releaseAdd() { holdAdd = false; addWaiter?.resume(); addWaiter = nil }
}

@MainActor
private final class IntegrationFixture {
    let suite = "SRSIntegration.\(UUID())"
    let defaults: UserDefaults
    let container: ModelContainer
    let app: AppContainer
    let probe = NotificationProbe()
    let notifications: NotificationService
    let store: SRSWidgetStore
    let integration: SRSIntegrationService
    let cards: FailableWidgetCards
    var date: Date

    init(date: Date = .now) throws {
        self.date = date
        defaults = try #require(UserDefaults(suiteName: suite))
        container = try TestContainer.makeContainer()
        app = try AppContainer.live(container: container, defaults: defaults, integrateSystemServices: false)
        notifications = NotificationService(client: probe)
        store = SRSWidgetStore(defaults: defaults)
        cards = FailableWidgetCards(base: app.cardRepository)
        integration = SRSIntegrationService(cards: cards, stats: app.statsRepository, defaults: defaults, store: store,
                                            notifications: notifications, now: { date }, reloadWidgets: {},
                                            language: { "en" }, theme: { "blue" }, localize: { $0 })
        app.transaction.onCommit = { [weak integration] in integration?.refresh() }
        integration.refresh()
    }
    deinit { UserDefaults.standard.removePersistentDomain(forName: suite) }

    func snapshot() throws -> SRSWidgetSnapshot {
        guard case .current(let snapshot) = store.read(at: date) else { throw CocoaError(.fileReadUnknown) }
        return snapshot
    }
}

@MainActor
private final class FailableWidgetCards: CardRepository {
    let base: CardRepository
    var fail = false
    init(base: CardRepository) { self.base = base }
    func fetchAll() throws -> [Card] { try base.fetchAll() }
    func fetch(id: UUID) throws -> Card? { try base.fetch(id: id) }
    func fetch(inGroup groupID: UUID) throws -> [Card] { try base.fetch(inGroup: groupID) }
    func fetchFavourites() throws -> [Card] { try base.fetchFavourites() }
    func search(_ query: String) throws -> [Card] { try base.search(query) }
    func totalCount() throws -> Int { try base.totalCount() }
    func favouritesCount() throws -> Int { try base.favouritesCount() }
    func count(inGroup groupID: UUID) throws -> Int { try base.count(inGroup: groupID) }
    func create(origin: String, translated: String, originDescription: String, translatedDescription: String, groups: [CardGroup], languagePair: StudyLanguagePair?) throws -> Card {
        try base.create(origin: origin, translated: translated, originDescription: originDescription, translatedDescription: translatedDescription, groups: groups, languagePair: languagePair)
    }
    func update(_ card: Card, origin: String, translated: String, originDescription: String, translatedDescription: String, groups: [CardGroup], languagePair: StudyLanguagePair?) throws {
        try base.update(card, origin: origin, translated: translated, originDescription: originDescription, translatedDescription: translatedDescription, groups: groups, languagePair: languagePair)
    }
    func toggleFavourite(_ card: Card) throws { try base.toggleFavourite(card) }
    func delete(_ card: Card) throws { try base.delete(card) }
    func recordAnswer(_ card: Card, correct: Bool) throws { try base.recordAnswer(card, correct: correct) }
    func exists(origin: String, translated: String, excluding cardID: UUID?, languagePair: StudyLanguagePair?) throws -> Bool { try base.exists(origin: origin, translated: translated, excluding: cardID, languagePair: languagePair) }
    func fetchDueToday(on date: Date, newCardsLimit: Int) throws -> [Card] { try base.fetchDueToday(on: date, newCardsLimit: newCardsLimit) }
    func dueTodayCount(on date: Date, newCardsLimit: Int) throws -> Int { try base.dueTodayCount(on: date, newCardsLimit: newCardsLimit) }
    func recordSRSReview(_ card: Card, quality: Int, on date: Date) throws { try base.recordSRSReview(card, quality: quality, on: date) }
    func srsOverview(on date: Date, newCardsLimit: Int) throws -> SRSOverview {
        if fail { throw CocoaError(.fileReadUnknown) }
        return try base.srsOverview(on: date, newCardsLimit: newCardsLimit)
    }
}

@Suite("Виджет, напоминания и маршруты")
@MainActor
struct SRSIntegrationTests {
    private func snapshot(date: Date = .now, due: Int = 0) -> SRSWidgetSnapshot {
        SRSWidgetSnapshot(dueToday: due, srsStreak: 3, nextReviewDate: nil, nextReviewCount: 0, updatedAt: date,
                          validUntil: StudyDay.end(of: date), timeZoneID: TimeZone.current.identifier)
    }

    @Test("Обновление после commit охватывает создание, ответ и удаление")
    func updatesOnCommittedMutations() throws {
        let f = try IntegrationFixture()
        #expect(try f.snapshot().dueToday == 0)
        let card = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        #expect(try f.snapshot().dueToday == 1)
        let session = try f.app.solveSessionCoordinator.currentSession(for: .srs)
        _ = try f.app.answerRecorder.record(card: card, session: session, correct: true, quality: .remembered)
        #expect(try f.snapshot().dueToday == 0)
        #expect(try f.snapshot().nextReviewCount == 1)
        try f.app.cardRepository.delete(card)
        #expect(try f.snapshot().nextReviewDate == nil)
    }

    @Test("Частичная тренировка, лимит и импорт обновляют снимок")
    func partialTrainingAndImport() throws {
        let f = try IntegrationFixture()
        f.defaults.set(2, forKey: "srsNewCardsPerDay")
        let vm = ImportDataViewModel(cardRepository: f.app.cardRepository, groupRepository: f.app.groupRepository,
                                     transaction: f.app.transaction, onComplete: {})
        vm.startImport(from: #"[{"name":"A","cards":[{"origin":"one","translated":"один"},{"origin":"two","translated":"два"},{"origin":"three","translated":"три"}]}]"#)
        vm.confirmImportWithDuplicates()
        #expect(try f.snapshot().dueToday == 2)
        let session = try f.app.solveSessionCoordinator.currentSession(for: .srs)
        let id = try #require(session.currentCardID)
        let card = try #require(try f.app.cardRepository.fetch(id: id))
        _ = try f.app.answerRecorder.record(card: card, session: session, correct: true, quality: .remembered)
        #expect(try f.snapshot().dueToday == 1)
        f.defaults.set(1, forKey: "srsNewCardsPerDay")
        f.integration.refresh()
        #expect(try f.snapshot().dueToday == 0)
    }

    @Test("Ошибка транзакции не публикует несохранённый снимок")
    func rollbackDoesNotPublish() throws {
        let f = try IntegrationFixture()
        let old = try f.snapshot()
        let tx = PersistenceTransaction(context: f.container.mainContext, save: { _ in throw CocoaError(.fileWriteUnknown) })
        var commits = 0
        tx.onCommit = { commits += 1; f.integration.refresh() }
        let repo = SwiftDataCardRepository(context: f.container.mainContext, transaction: tx)
        #expect(throws: (any Error).self) { try repo.create(origin: "fail", translated: "ошибка", groups: []) }
        #expect(commits == 0)
        #expect(try f.snapshot() == old)
    }

    @Test("Ошибка чтения сохраняет прежние числа и показывает unavailable; повтор восстанавливает")
    func failedReadPreservesSnapshot() throws {
        let f = try IntegrationFixture()
        _ = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        let old = try f.snapshot()
        f.cards.fail = true
        f.integration.refresh()
        #expect(f.integration.errorMessage != nil)
        #expect(f.store.read(at: f.date) == .unavailable(old))
        f.cards.fail = false
        f.integration.refresh()
        #expect(try f.snapshot().dueToday == 1)
        #expect(f.integration.errorMessage == nil)
    }

    @Test("Пустое, повреждённое и недоступное хранилище не становятся нулевой очередью")
    func missingAndCorruptStore() throws {
        let f = try IntegrationFixture()
        f.defaults.removeObject(forKey: "srs_widget_snapshot_v1")
        #expect(f.store.read(at: f.date) == .missing)
        f.defaults.set(Data("bad json".utf8), forKey: "srs_widget_snapshot_v1")
        #expect(f.store.read(at: f.date) == .unavailable(nil))
        #expect(SRSWidgetStore(defaults: nil).read(at: f.date) == .unavailable(nil))
    }

    @Test("Полночь, истечение срока и смена зоны делают вчерашнее всё готово устаревшим")
    func snapshotExpires() throws {
        let now = Date.now
        var value = snapshot(date: now)
        #expect(value.isCurrent(at: now))
        value.validUntil = now.addingTimeInterval(60)
        #expect(!value.isCurrent(at: now.addingTimeInterval(60)))
        #expect(!value.isCurrent(at: StudyDay.end(of: now)))
        var otherZone = StudyDay.calendar
        otherZone.timeZone = try #require(TimeZone(identifier: TimeZone.current.identifier == "UTC" ? "Asia/Tokyo" : "UTC"))
        #expect(!value.isCurrent(at: now, calendar: otherZone))
        #expect(!value.isCurrent(at: now.addingTimeInterval(-1)))
    }

    @Test("Старый снимок v1 без optional-полей читается, но не остаётся свежим бессрочно")
    func legacySnapshot() throws {
        let f = try IntegrationFixture()
        let old = snapshot(date: f.date)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        json.removeValue(forKey: "validUntil")
        json.removeValue(forKey: "timeZoneID")
        f.defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: "srs_widget_snapshot_v1")
        guard case .current = f.store.read(at: f.date) else { Issue.record("Старый снимок не читается"); return }
        guard case .stale = f.store.read(at: f.date.addingTimeInterval(7 * 3600)) else { Issue.record("Старый снимок не устаревает"); return }
    }

    @Test("Сегодня всё выполнено: будущие назначения всё равно получают напоминания")
    func futureReminders() async throws {
        let f = try IntegrationFixture()
        let card = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        let session = try f.app.solveSessionCoordinator.currentSession(for: .srs)
        _ = try f.app.answerRecorder.record(card: card, session: session, correct: true, quality: .remembered)
        f.integration.setRemindersEnabled(true)
        await f.notifications.waitUntilIdle()
        #expect(try f.snapshot().dueToday == 0)
        #expect(f.probe.requests.count == SRSReminderPlan.capacity)
        let tomorrow = StudyDay.end(of: f.date)
        #expect(f.probe.requests.values.allSatisfy { ($0.components.day ?? 0) >= 1 && $0.components.hour == 20 })
        #expect(f.probe.requests["daily_srs_reminder.0"]?.components.day == StudyDay.calendar.component(.day, from: tomorrow))
        #expect(f.probe.permissionRequests == 0)
    }

    @Test("Напоминания выключены по умолчанию; выключение удаляет все принадлежащие им запросы")
    func optInAndCancel() async throws {
        let f = try IntegrationFixture()
        _ = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        await f.notifications.waitUntilIdle()
        #expect(!f.integration.remindersEnabled)
        #expect(f.probe.requests.isEmpty)
        f.integration.setRemindersEnabled(true)
        await f.notifications.waitUntilIdle()
        #expect(!f.probe.requests.isEmpty)
        f.integration.setRemindersEnabled(false)
        await f.notifications.waitUntilIdle()
        #expect(f.probe.requests.isEmpty)
        #expect(f.probe.permissionRequests == 0)
    }

    private func plan(hour: Int = 20) -> [SRSReminder] {
        Array(SRSReminderPlan.make(firstDueDay: .now, now: .now, hour: hour, minute: 10, title: "title", body: "body").prefix(2))
    }

    @Test("Отмена во время чтения разрешения не восстанавливает напоминание")
    func cancelWhileReadingAuthorization() async throws {
        let client = NotificationProbe()
        client.holdAuthorization = true
        let service = NotificationService(client: client)
        service.replace(with: plan())
        for _ in 0..<100 where client.authorizationWaiter == nil { await Task.yield() }
        _ = try #require(client.authorizationWaiter)
        service.replace(with: [])
        client.releaseAuthorization()
        await service.waitUntilIdle()
        #expect(client.requests.isEmpty)
    }

    @Test("Отмена уже начавшегося add удаляет его запоздалый результат")
    func cancelDuringAdd() async throws {
        let client = NotificationProbe()
        client.holdAdd = true
        let service = NotificationService(client: client)
        service.replace(with: plan())
        for _ in 0..<100 where client.addWaiter == nil { await Task.yield() }
        _ = try #require(client.addWaiter)
        service.replace(with: [])
        client.releaseAdd()
        await service.waitUntilIdle()
        #expect(client.requests.isEmpty)
    }

    @Test("Новый запрос времени побеждает запоздалое старое планирование")
    func latestPlanWins() async throws {
        let client = NotificationProbe()
        client.holdAdd = true
        let service = NotificationService(client: client)
        service.replace(with: plan(hour: 20))
        for _ in 0..<100 where client.addWaiter == nil { await Task.yield() }
        _ = try #require(client.addWaiter)
        let latest = plan(hour: 18)
        service.replace(with: latest)
        client.releaseAdd()
        await service.waitUntilIdle()
        #expect(Set(client.requests.keys) == Set(latest.map(\.identifier)))
        #expect(client.requests.values.allSatisfy { $0.components.hour == 18 })
    }

    @Test("Отказ в разрешении не вызывает повторный запрос без действия пользователя")
    func deniedPermission() async {
        let client = NotificationProbe()
        client.status = .denied
        let service = NotificationService(client: client)
        service.replace(with: plan())
        await service.waitUntilIdle()
        #expect(client.requests.isEmpty)
        #expect(client.permissionRequests == 0)
        #expect(service.authorizationStatus == .denied)
    }

    @Test("Ошибка добавления уведомления доступна UI и допускает повтор")
    func addErrorAndRetry() async {
        let client = NotificationProbe()
        client.failAdd = true
        let service = NotificationService(client: client)
        service.replace(with: plan())
        await service.waitUntilIdle()
        #expect(service.errorMessage != nil)
        client.failAdd = false
        service.replace(with: plan())
        await service.waitUntilIdle()
        #expect(service.errorMessage == nil)
        #expect(client.requests.count == 2)
    }

    @Test("Новые и прежние ссылки сохраняют маршрут до готовности UI", arguments: ["leksipo://srs", "leksipo://srs/", "LEKSIPO://srs", "englishwords://srs", "englishwords://srs/"])
    func pendingRoute(url: String) throws {
        let router = AppRouter()
        let parsed = try #require(URL(string: url))
        #expect(router.handle(parsed))
        #expect(router.pendingRoute == .srs)
        router.consume(.srs)
        #expect(router.pendingRoute == nil)
    }

    @Test("Проверяются host, scheme, path и параметры deep link", arguments: ["leksipo://other", "other://srs", "leksipo://srs/other", "leksipo://srs?x=1", "leksipo://srs#x", "leksipo://user@srs", "leksipo://srs:123", "englishwords://other", "englishwords://srs/other", "englishwords://srs?x=1", "englishwords://srs#x", "englishwords://user@srs", "englishwords://srs:123"])
    func invalidRoutes(url: String) throws {
        let router = AppRouter()
        let parsed = try #require(URL(string: url))
        #expect(!router.handle(parsed))
        #expect(router.pendingRoute == nil)
    }
}

extension SRSIntegrationTests {
    @Test("Восстановление и удаление всех данных обновляют виджет и очищают расписание")
    func restoreAndDeleteAll() async throws {
        let f = try IntegrationFixture()
        let empty = try BackupService.createBackup(context: f.container.mainContext)
        _ = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        f.integration.setRemindersEnabled(true)
        await f.notifications.waitUntilIdle()
        #expect(!f.probe.requests.isEmpty)
        try BackupService.restoreBackup(from: empty, context: f.container.mainContext, transaction: f.app.transaction)
        await f.notifications.waitUntilIdle()
        #expect(try f.snapshot().dueToday == 0)
        #expect(f.probe.requests.isEmpty)
        _ = try f.app.cardRepository.create(origin: "two", translated: "два", groups: [])
        let vm = SettingsViewModel(cardRepository: f.app.cardRepository, groupRepository: f.app.groupRepository,
                                   statsRepository: f.app.statsRepository, solveSessionStore: f.app.solveSessionStore,
                                   transaction: f.app.transaction, onRestore: {})
        vm.deleteAllData()
        await f.notifications.waitUntilIdle()
        #expect(vm.errorMessage == nil)
        #expect(try f.snapshot().dueToday == 0)
        #expect(f.probe.requests.isEmpty)
    }

    @Test("Изолированные предпочтения передают язык и тему сразу, включая первоначальную запись")
    func initialAppearance() throws {
        let f = try IntegrationFixture()
        #expect(f.defaults.string(forKey: "widget_current_theme") == "blue")
        #expect(f.defaults.string(forKey: "appLanguage") == "en")
        #expect(SRSWidgetText.string("settings_title", language: "en") != "settings_title")
        #expect(SRSWidgetText.string("settings_title", language: "en") != SRSWidgetText.string("settings_title", language: "ru"))
    }

    @Test("Планирование не удаляет чужие уведомления и снимает старый legacy-запрос")
    func preservesOtherNotifications() async {
        let client = NotificationProbe()
        let base = plan()
        client.requests["other_feature"] = SRSReminder(identifier: "other_feature", components: DateComponents(), title: "other", body: "")
        client.requests["daily_srs_reminder"] = SRSReminder(identifier: "daily_srs_reminder", components: DateComponents(), title: "old", body: "")
        let service = NotificationService(client: client)
        service.replace(with: base)
        await service.waitUntilIdle()
        #expect(client.requests["other_feature"] != nil)
        #expect(client.requests["daily_srs_reminder"] == nil)
        #expect(client.requests.count == base.count + 1)
    }

    @Test("Выбранное время сохраняется, а запрос разрешения вызывается только явно")
    func savedTimeAndExplicitPermission() async throws {
        let f = try IntegrationFixture()
        f.integration.setReminderTime(hour: 9, minute: 35)
        #expect(f.integration.reminderHour == 9)
        #expect(f.integration.reminderMinute == 35)
        #expect(f.probe.permissionRequests == 0)
        let granted = await f.notifications.requestPermission()
        #expect(granted)
        #expect(f.probe.permissionRequests == 1)
        #expect(f.notifications.authorizationStatus == .authorized)
    }

    @Test("Прошедшее время не даёт запрос в прошлом, будущие задания не заменяются сегодняшними")
    func reminderDates() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Moscow"))
        let day = try #require(StudyDay.date(for: "2026-11-03", calendar: calendar))
        let now = try #require(calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day))
        let today = SRSReminderPlan.make(firstDueDay: now, now: now, hour: 20, minute: 0, title: "", body: "", calendar: calendar)
        #expect(today.first?.components.day == 4)
        #expect(today.count == SRSReminderPlan.capacity)
        #expect(today.allSatisfy { $0.components.timeZone == nil })
        let distant = try #require(StudyDay.date(for: "2027-07-15", calendar: calendar))
        let future = SRSReminderPlan.make(firstDueDay: distant, now: now, hour: 20, minute: 0, title: "", body: "", calendar: calendar)
        #expect(future.first?.components.month == 7)
        #expect(future.first?.components.day == 15)
        #expect(future.first?.components.year == 2027)
        #expect(SRSReminderPlan.make(firstDueDay: nil, now: now, hour: 20, minute: 0, title: "", body: "").isEmpty)
    }

    @Test("DST не дублирует дни расписания", arguments: ["2026-03-07", "2026-10-31"])
    func reminderDST(key: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let date = try #require(StudyDay.date(for: key, calendar: calendar))
        let result = SRSReminderPlan.make(firstDueDay: date, now: date, hour: 20, minute: 0, title: "", body: "", calendar: calendar)
        #expect(result.count == SRSReminderPlan.capacity)
        let days = result.map { "\($0.components.year ?? 0)-\($0.components.month ?? 0)-\($0.components.day ?? 0)" }
        #expect(Set(days).count == result.count)
        #expect(result.allSatisfy { $0.components.hour == 20 })
    }
}

extension SRSIntegrationTests {
    @Test("Сбой общего контейнера виджета не блокирует корректное расписание напоминаний")
    func widgetStorageFailureKeepsRemindersWorking() async throws {
        let f = try IntegrationFixture()
        _ = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        f.defaults.set(true, forKey: "srsRemindersEnabled")
        let integration = SRSIntegrationService(cards: f.cards, stats: f.app.statsRepository, defaults: f.defaults,
                                                store: SRSWidgetStore(defaults: nil), notifications: f.notifications,
                                                now: { f.date }, reloadWidgets: {}, language: { "en" }, theme: { "blue" }, localize: { $0 })
        integration.refresh()
        await f.notifications.waitUntilIdle()
        #expect(integration.errorMessage != nil)
        #expect(f.probe.requests.count == SRSReminderPlan.capacity)
    }
}

extension SRSIntegrationTests {
    @Test("Файл группы сохраняет маршрут до готовности интерфейса")
    func groupFileRoute() {
        let router = AppRouter()
        let url = URL(fileURLWithPath: "/tmp/К экзамену.JSON")
        #expect(router.handle(url))
        #expect(router.pendingRoute == .groupImport(url))
        router.consume(.srs)
        #expect(router.pendingRoute == .groupImport(url))
        router.consume(.groupImport(url))
        #expect(router.pendingRoute == nil)
    }

    @Test("Другие файлы и удалённые ссылки не заменяют ожидающий маршрут", arguments: ["https://example.com/group.json", "file:///tmp/group.txt", "file:///tmp/group.json/", "file:///tmp/group.json?x=1", "file:///tmp/group.json#fragment"])
    func rejectedGroupRoutes(value: String) throws {
        let router = AppRouter()
        let srs = try #require(URL(string: "leksipo://srs"))
        #expect(router.handle(srs))
        let file = try #require(URL(string: value))
        #expect(!router.handle(file))
        #expect(router.pendingRoute == .srs)
    }
}


extension SRSIntegrationTests {
    @Test("Закрепление остаётся в виджете и напоминании на сегодня до успешного ответа")
    func relearningKeepsTodayReminder() async throws {
        let date = StudyDay.calendar.startOfDay(for: .now)
        let f = try IntegrationFixture(date: date)
        f.integration.setRemindersEnabled(true)
        let card = try f.app.cardRepository.create(origin: "one", translated: "один", groups: [])
        let original = try f.app.solveSessionCoordinator.currentSession(for: .srs)
        let pending = try f.app.answerRecorder.record(card: card, session: original, correct: false, quality: .forgot, on: date)
        await f.notifications.waitUntilIdle()
        #expect(try f.snapshot().dueToday == 1)
        #expect(try f.snapshot().nextReviewCount == 0)
        #expect(f.probe.requests["daily_srs_reminder.0"]?.components.day == StudyDay.calendar.component(.day, from: date))
        _ = try f.app.answerRecorder.record(card: card, session: pending, correct: true, quality: .remembered, on: date)
        await f.notifications.waitUntilIdle()
        #expect(try f.snapshot().dueToday == 0)
        #expect(try f.snapshot().nextReviewCount == 1)
        let tomorrow = StudyDay.end(of: date)
        #expect(f.probe.requests["daily_srs_reminder.0"]?.components.day == StudyDay.calendar.component(.day, from: tomorrow))
    }
}
