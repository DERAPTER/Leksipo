//
//  SolveSessionCoordinatorTests.swift
//  English Words Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
import SwiftData
@testable import English_Words

@Suite("SolveSessionCoordinator")
@MainActor
final class SolveSessionCoordinatorTests {
    
    // MARK: - Fixture
    
    let repos: TestContainer.Repositories
    let defaults: UserDefaults
    let store: SolveSessionStore
    let coordinator: SolveSessionCoordinator
    private let suiteName: String
    
    init() throws {
        repos = try TestContainer.makeRepositories()
        
        // Уникальный suite для каждого теста — полная изоляция.
        suiteName = "SolveSessionCoordinatorTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        
        store = SolveSessionStore(defaults: defaults)
        coordinator = SolveSessionCoordinator(store: store, cardRepository: repos.card, defaults: defaults)
        
    }

    deinit { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    // MARK: - Helpers
    
    @discardableResult
    private func makeGroup(name: String = "G") throws -> CardGroup {
        try repos.group.create(name: name)
    }
    
    @discardableResult
    private func makeCard(
        origin: String = "x",
        translated: String = "y",
        groups: [CardGroup] = []
    ) throws -> Card {
        try repos.card.create(origin: origin, translated: translated, groups: groups)
    }
    
    /// Делает карточку «просроченной» — lastReviewDate в прошлом, nextReviewDate в прошлом.
    private func markOverdue(_ card: Card, daysAgo: Int = 2) throws {
        let cal = Calendar.current
        let past = cal.date(byAdding: .day, value: -daysAgo, to: .now)!
        card.lastReviewDate = past
        card.nextReviewDate = past
        card.intervalDays = 1
        card.repetitions = 1
        try repos.container.mainContext.save()
    }
    
    // MARK: - currentSession: fresh
    
    @Test("currentSession для user-группы создаёт новую сессию, если её нет")
    func currentSessionCreatesFresh() throws {
        let g = try makeGroup()
        let c1 = try makeCard(origin: "a", groups: [g])
        let c2 = try makeCard(origin: "b", groups: [g])
        
        let session = try coordinator.currentSession(for: .user(g.id))
        
        #expect(session.totalCount == 2)
        #expect(Set(session.unsolvedIDs) == Set([c1.id, c2.id]))
        #expect(session.successIDs.isEmpty)
        #expect(session.failIDs.isEmpty)
    }
    
    @Test("currentSession для system(.allCards) собирает все карточки")
    func currentSessionAllCards() throws {
        _ = try makeCard(origin: "a")
        _ = try makeCard(origin: "b")
        _ = try makeCard(origin: "c")
        
        let session = try coordinator.currentSession(for: .system(.allCards))
        #expect(session.totalCount == 3)
    }
    
    @Test("currentSession для system(.favourites) собирает только избранные")
    func currentSessionFavourites() throws {
        let a = try makeCard(origin: "a")
        _ = try makeCard(origin: "b")
        try repos.card.toggleFavourite(a)
        
        let session = try coordinator.currentSession(for: .system(.favourites))
        #expect(session.unsolvedIDs == [a.id])
    }
    
    @Test("currentSession: сохранённая сессия перезаписывается в store после reconcile")
    func currentSessionPersistsAfterReconcile() throws {
        let g = try makeGroup()
        let c1 = try makeCard(origin: "a", groups: [g])
        _ = try makeCard(origin: "b", groups: [g])
        
        // Первый вызов создаёт и сохраняет
        _ = try coordinator.currentSession(for: .user(g.id))
        
        // Добавим третью карточку
        let c3 = try makeCard(origin: "c", groups: [g])
        
        // Второй вызов подхватывает новую через reconcile
        let session = try coordinator.currentSession(for: .user(g.id))
        #expect(session.unsolvedIDs.contains(c3.id))
        
        // store содержит обновлённую сессию
        let stored = try store.load(for: .user(g.id))
        #expect(stored?.unsolvedIDs.contains(c3.id) == true)
        #expect(stored?.unsolvedIDs.contains(c1.id) == true)
    }
    
    // MARK: - currentSession: reconcile
    
    @Test("reconcile: удаляет несуществующие карточки из всех трёх массивов")
    func reconcileRemovesMissingCards() throws {
        let g = try makeGroup()
        let realCard = try makeCard(origin: "a", groups: [g])
        let fakeID = UUID()
        
        // Готовим «грязную» сессию с фиктивными ID
        var dirty = SolveSession(groupKey: .user(g.id), cardIDs: [])
        dirty.unsolvedIDs = [fakeID, realCard.id]
        dirty.successIDs = [fakeID]
        dirty.failIDs = [fakeID]
        try store.save(dirty, for: .user(g.id))
        
        let cleaned = try coordinator.currentSession(for: .user(g.id))
        
        #expect(!cleaned.unsolvedIDs.contains(fakeID))
        #expect(!cleaned.successIDs.contains(fakeID))
        #expect(!cleaned.failIDs.contains(fakeID))
        #expect(cleaned.unsolvedIDs.contains(realCard.id))
    }
    
    @Test("reconcile: добавляет новые карточки в unsolved")
    func reconcileAddsNewCards() throws {
        let g = try makeGroup()
        let c1 = try makeCard(origin: "a", groups: [g])
        
        // Создаём сессию из одной карточки
        _ = try coordinator.currentSession(for: .user(g.id))
        
        // Добавляем вторую
        let c2 = try makeCard(origin: "b", groups: [g])
        
        // Reconcile добавляет c2
        let session = try coordinator.currentSession(for: .user(g.id))
        
        #expect(Set(session.unsolvedIDs) == Set([c1.id, c2.id]))
    }
    
    @Test("reconcile: сохраняет success/fail по существующим карточкам")
    func reconcileKeepsValidProgress() throws {
        let g = try makeGroup()
        let c1 = try makeCard(origin: "a", groups: [g])
        let c2 = try makeCard(origin: "b", groups: [g])
        
        // Имитируем состояние: c1 отвечена правильно, c2 ещё нет
        var dirty = SolveSession(groupKey: .user(g.id), cardIDs: [])
        dirty.unsolvedIDs = [c2.id]
        dirty.successIDs = [c1.id]
        try store.save(dirty, for: .user(g.id))
        
        let session = try coordinator.currentSession(for: .user(g.id))
        
        #expect(session.successIDs == [c1.id])
        #expect(session.unsolvedIDs == [c2.id])
    }
    
    @Test("reconcile: удаление карточки из группы сокращает сессию")
    func reconcileAfterCardDeletion() throws {
        let g = try makeGroup()
        let c1 = try makeCard(origin: "a", groups: [g])
        let c2 = try makeCard(origin: "b", groups: [g])
        
        _ = try coordinator.currentSession(for: .user(g.id))
        
        // Удаляем карточку полностью
        try repos.card.delete(c2)
        
        let session = try coordinator.currentSession(for: .user(g.id))
        #expect(session.totalCount == 1)
        #expect(session.unsolvedIDs == [c1.id])
    }
    
    // MARK: - currentSession: SRS — без reconcile
    
    @Test("SRS: currentSession создаёт новую сессию из due-карточек")
    func srsCreatesFresh() throws {
        let c1 = try makeCard(origin: "a")
        let c2 = try makeCard(origin: "b")
        
        let session = try coordinator.currentSession(for: .srs)
        #expect(Set(session.unsolvedIDs) == Set([c1.id, c2.id]))
        #expect(session.groupKeyString == "srs")
    }
    
    @Test("SRS: currentSession подхватывает новые назначения")
    func srsRefreshesAssignments() throws {
        let c1 = try makeCard(origin: "a")
        
        // Первый вызов создаёт сессию
        let original = try coordinator.currentSession(for: .srs)
        #expect(original.unsolvedIDs == [c1.id])
        
        // Добавляем новое назначение в пределах дневного лимита.
        let c2 = try makeCard(origin: "b")
        
        // SRS обновляет очередь, сохраняя приоритет старых карточек.
        let second = try coordinator.currentSession(for: .srs)
        #expect(second.unsolvedIDs == [c1.id, c2.id])
    }
    
    @Test("SRS: удалённые UUID исключаются, пустая очередь очищается")
    func srsRemovesStaleIDs() throws {
        let c1 = try makeCard(origin: "a")
        _ = try coordinator.currentSession(for: .srs)
        try repos.card.delete(c1)
        let session = try coordinator.currentSession(for: .srs)
        #expect(session.unsolvedIDs.isEmpty)
        #expect(try store.load(for: .srs) == nil)
    }

    // MARK: - restartAll
    
    @Test("restartAll: полностью сбрасывает сессию")
    func restartAllResets() throws {
        let g = try makeGroup()
        _ = try makeCard(origin: "a", groups: [g])
        _ = try makeCard(origin: "b", groups: [g])
        
        // Создаём сессию, отмечаем одну
        var session = try coordinator.currentSession(for: .user(g.id))
        session = try coordinator.markCorrect(session)
        #expect(try store.load(for: .user(g.id))?.successIDs.count == 1)
        
        // Restart — всё обнулилось
        let fresh = try coordinator.restartAll(for: .user(g.id))
        #expect(fresh.successIDs.isEmpty)
        #expect(fresh.failIDs.isEmpty)
        #expect(fresh.unsolvedIDs.count == 2)
    }
    
    // MARK: - restartMistakes
    
    @Test("restartMistakes: оставляет только failIDs, обнуляет success")
    func restartMistakes() throws {
        let g = try makeGroup()
        _ = try makeCard(origin: "a", groups: [g])
        _ = try makeCard(origin: "b", groups: [g])
        _ = try makeCard(origin: "c", groups: [g])
        
        var session = try coordinator.currentSession(for: .user(g.id))
        session = try coordinator.markCorrect(session)
        session = try coordinator.markWrong(session)
        
        let failedID = session.failIDs[0]
        
        let restarted = try coordinator.restartMistakes(session)
        #expect(restarted.successIDs.isEmpty)
        #expect(restarted.failIDs.isEmpty)
        #expect(restarted.unsolvedIDs == [failedID])
        
        // И сохранилось
        #expect(try store.load(for: .user(g.id))?.unsolvedIDs == [failedID])
    }
    
    // MARK: - markCorrect / markWrong
    
    @Test("markCorrect: перемещает текущую в success и сохраняет в store")
    func markCorrectSaves() throws {
        let g = try makeGroup()
        let c1 = try makeCard(origin: "a", groups: [g])
        _ = try makeCard(origin: "b", groups: [g])
        
        let session = try coordinator.currentSession(for: .user(g.id))
        let firstID = session.unsolvedIDs[0]
        
        let updated = try coordinator.markCorrect(session)
        #expect(updated.successIDs == [firstID])
        #expect(!updated.unsolvedIDs.contains(firstID))
        
        // Сохранено в store
        #expect(try store.load(for: .user(g.id))?.successIDs == [firstID])
    }
    
    @Test("markWrong: перемещает текущую в fail и сохраняет в store")
    func markWrongSaves() throws {
        let g = try makeGroup()
        _ = try makeCard(origin: "a", groups: [g])
        
        let session = try coordinator.currentSession(for: .user(g.id))
        let firstID = session.unsolvedIDs[0]
        
        let updated = try coordinator.markWrong(session)
        #expect(updated.failIDs == [firstID])
        #expect(try store.load(for: .user(g.id))?.failIDs == [firstID])
    }
    
    // MARK: - persistIfNeeded: автоматическая очистка при завершении
    
    @Test("Завершение без ошибок: сессия удаляется из store")
    func completedWithoutMistakesClearsSession() throws {
        let g = try makeGroup()
        _ = try makeCard(origin: "a", groups: [g])
        
        var session = try coordinator.currentSession(for: .user(g.id))
        session = try coordinator.markCorrect(session)
        
        // Сессия завершена без ошибок — persistIfNeeded вызвал store.clear
        #expect(try store.load(for: .user(g.id)) == nil)
    }
    
    @Test("Завершение с ошибками: сессия остаётся (для повтора ошибок)")
    func completedWithMistakesKeepsSession() throws {
        let g = try makeGroup()
        _ = try makeCard(origin: "a", groups: [g])
        
        var session = try coordinator.currentSession(for: .user(g.id))
        session = try coordinator.markWrong(session)
        
        // Есть failIDs → сессия сохраняется
        #expect(try store.load(for: .user(g.id)) != nil)
        #expect(try store.load(for: .user(g.id))?.failIDs.count == 1)
    }
    
    @Test("SRS: после ответа на все карточки сессия автоматически чистится")
    func srsSessionAutoClearsOnCompletion() throws {
        _ = try makeCard(origin: "a")
        _ = try makeCard(origin: "b")
        
        var session = try coordinator.currentSession(for: .srs)
        session = try coordinator.markCorrect(session)
        // Ещё не завершена
        #expect(try store.load(for: .srs) != nil)
        
        session = try coordinator.markCorrect(session)
        // Завершена → очищена (failIDs пуст, success заполнен → isCompletedWithoutMistakes)
        #expect(try store.load(for: .srs) == nil)
    }
    
    // MARK: - clear
    
    @Test("clear: удаляет сессию из store")
    func clear() throws {
        let g = try makeGroup()
        _ = try makeCard(origin: "a", groups: [g])
        _ = try coordinator.currentSession(for: .user(g.id))
        #expect(try store.load(for: .user(g.id)) != nil)
        
        try coordinator.clear(for: .user(g.id))
        #expect(try store.load(for: .user(g.id)) == nil)
    }
    
    // MARK: - SRS + лимит новых карточек
    
    @Test("SRS: уважает лимит новых карточек из UserDefaults")
    func srsRespectsNewCardsLimit() throws {
        defaults.set(2, forKey: "srsNewCardsPerDay")
        defer { defaults.removeObject(forKey: "srsNewCardsPerDay") }
        
        for i in 0..<5 {
            _ = try makeCard(origin: "w\(i)")
        }
        
        let session = try coordinator.currentSession(for: .srs)
        #expect(session.unsolvedIDs.count == 2)
    }
    
    @Test("SRS: лимит 0 или отсутствие ключа → используется дефолт 20")
    func srsDefaultLimitIs20() throws {
        // В init мы ключ убрали, значит integer(forKey:) == 0 → effectiveLimit = 20
        for i in 0..<25 {
            _ = try makeCard(origin: "w\(i)")
        }
        
        let session = try coordinator.currentSession(for: .srs)
        #expect(session.unsolvedIDs.count == 20)
    }
    
    // MARK: - Сквозной сценарий
    
    @Test("Сценарий: solve → reconcile → restartMistakes → завершение")
    func fullScenario() throws {
        let g = try makeGroup()
        for i in 0..<4 {
            _ = try makeCard(origin: "c\(i)", groups: [g])
        }
        
        // 1. Создаём сессию
        var session = try coordinator.currentSession(for: .user(g.id))
        #expect(session.totalCount == 4)
        
        // 2. Отвечаем: правильно, ошибка, правильно, ошибка
        session = try coordinator.markCorrect(session)
        session = try coordinator.markWrong(session)
        session = try coordinator.markCorrect(session)
        session = try coordinator.markWrong(session)
        
        // 3. Сессия завершена с ошибками — есть в store
        #expect(session.failIDs.count == 2)
        #expect(try store.load(for: .user(g.id)) != nil)
        
        // 4. Restart по ошибкам
        session = try coordinator.restartMistakes(session)
        #expect(session.unsolvedIDs.count == 2)
        #expect(session.successIDs.isEmpty)
        
        // 5. Отвечаем правильно обе
        session = try coordinator.markCorrect(session)
        session = try coordinator.markCorrect(session)
        
        // 6. Завершено без ошибок → store очищен
        #expect(try store.load(for: .user(g.id)) == nil)
    }
}
