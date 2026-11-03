//
//  AchievementsServiceTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 06.10.2026.
//

import Testing
import Foundation
import SwiftData
@testable import English_Words

@Suite("AchievementsService")
@MainActor
struct AchievementsServiceTests {
    
    // MARK: - Fixture
    
    let repos: TestContainer.Repositories
    let service: AchievementsService
    
    init() throws {
        repos = try TestContainer.makeRepositories()
        service = AchievementsService(
            statsRepository: repos.stats,
            cardRepository: repos.card,
            groupRepository: repos.group
        )
    }
    
    // MARK: - Helpers
    
    @discardableResult
    private func makeCard(origin: String = "x", translated: String = "y") throws -> Card {
        try repos.card.create(origin: origin, translated: translated, groups: [])
    }
    
    @discardableResult
    private func makeGroup(name: String = "G") throws -> CardGroup {
        try repos.group.create(name: name)
    }
    
    private func settings() throws -> UserSettings {
        try repos.stats.settings()
    }
    
    // MARK: - evaluate: пустая база
    
    @Test("evaluate: пустая база → ничего не разблокировано")
    func evaluateEmptyBase() throws {
        let unlocked = service.evaluate()
        #expect(unlocked.isEmpty)
        #expect(try settings().unlockedAchievementIDs.isEmpty)
    }
    
    @Test("evaluate: не меняет recentlyUnlocked, если ничего не разблокировано")
    func evaluateDoesNotTouchRecentlyUnlockedOnEmpty() {
        _ = service.evaluate()
        #expect(service.recentlyUnlocked == nil)
    }
    
    // MARK: - evaluate: разблокировка
    
    @Test("evaluate: 10 карточек разблокирует cards_10")
    func evaluateCards10() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        
        let unlocked = service.evaluate()
        #expect(unlocked.map(\.id) == ["cards_10"])
        #expect(try settings().isUnlocked("cards_10") == true)
    }
    
    @Test("evaluate: несколько категорий сразу — всё попадает в результат")
    func evaluateMultipleCategories() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = try makeGroup(name: "A")
        
        let unlocked = service.evaluate()
        let ids = Set(unlocked.map(\.id))
        #expect(ids == ["cards_10", "group_1"])
    }
    
    @Test("evaluate: recentlyUnlocked = первый из разблокированных")
    func recentlyUnlockedIsSet() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        
        let unlocked = service.evaluate()
        #expect(service.recentlyUnlocked?.id == unlocked.first?.id)
        #expect(service.recentlyUnlocked?.id == "cards_10")
    }
    
    @Test("evaluate: возвращает только НОВЫЕ разблокировки, не ранее полученные")
    func evaluateReturnsOnlyNew() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        let first = service.evaluate()
        #expect(first.map(\.id) == ["cards_10"])
        
        // Второй вызов — уже ничего нового
        let second = service.evaluate()
        #expect(second.isEmpty)
    }
    
    @Test("evaluate: не перезаписывает recentlyUnlocked, если новых нет")
    func evaluateKeepsRecentlyUnlockedOnNoNew() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        let initial = service.recentlyUnlocked
        #expect(initial?.id == "cards_10")
        
        // Ещё один вызов без новых разблокировок — recentlyUnlocked остаётся
        _ = service.evaluate()
        #expect(service.recentlyUnlocked?.id == "cards_10")
    }
    
    // MARK: - evaluate: источник данных
    
    @Test("evaluate: cardsSolved берётся из settings.totalSolved, а не из карточек")
    func evaluateCardsSolvedFromSettings() throws {
        let s = try settings()
        s.totalSolved = 50
        try repos.container.mainContext.save()
        
        let unlocked = service.evaluate()
        let ids = Set(unlocked.map(\.id))
        #expect(ids.contains("solved_10"))
        #expect(ids.contains("solved_50"))
    }
    
    @Test("evaluate: streak берётся из settings.streak")
    func evaluateStreakFromSettings() throws {
        let s = try settings()
        s.streak = 7
        try repos.container.mainContext.save()
        
        let unlocked = service.evaluate()
        let ids = Set(unlocked.map(\.id))
        #expect(ids == ["streak_3", "streak_7"])
    }
    
    @Test("evaluate: daysGoalCompleted считается через totalDaysGoalCompleted")
    func evaluateDaysGoalCompleted() throws {
        // Вставляем 3 записи с goalCompleted = true
        for day in 10...12 {
            var c = DateComponents()
            c.year = 2026; c.month = 3; c.day = day
            let date = Calendar.current.date(from: c)!
            let stat = DailyStat(date: date, goalCompleted: true)
            repos.container.mainContext.insert(stat)
        }
        try repos.container.mainContext.save()
        
        let unlocked = service.evaluate()
        #expect(unlocked.map(\.id) == ["goal_1"])
    }
    
    @Test("evaluate: favouritesCount берётся из карточек")
    func evaluateFavourites() throws {
        for i in 0..<5 {
            let c = try makeCard(origin: "w\(i)")
            try repos.card.toggleFavourite(c)
        }
        
        let unlocked = service.evaluate()
        let ids = Set(unlocked.map(\.id))
        #expect(ids == ["fav_1", "fav_5"])
    }
    
    @Test("evaluate: userGroupsCount берётся из репозитория групп")
    func evaluateGroups() throws {
        for i in 0..<5 {
            _ = try makeGroup(name: "G\(i)")
        }
        
        let unlocked = service.evaluate()
        let ids = Set(unlocked.map(\.id))
        #expect(ids == ["group_1", "group_5"])
    }
    
    // MARK: - refresh
    
    @Test("refresh: заполняет allAchievements всеми достижениями каталога")
    func refreshPopulatesAllAchievements() throws {
        service.refresh()
        #expect(service.allAchievements.count == AchievementsCatalog.all.count)
    }
    
    @Test("refresh: НЕ разблокирует достижения")
    func refreshDoesNotUnlock() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        
        service.refresh()
        
        #expect(try settings().unlockedAchievementIDs.isEmpty)
        #expect(service.recentlyUnlocked == nil)
    }
    
    @Test("refresh: корректно отражает уже разблокированные достижения")
    func refreshReflectsUnlocked() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        
        service.refresh()
        
        let cards10 = service.allAchievements.first(where: { $0.id == "cards_10" })
        #expect(cards10?.isUnlocked == true)
        #expect(cards10?.unlockedDate != nil)
    }
    
    @Test("refresh: сохраняет дату разблокировки")
    func refreshKeepsUnlockDate() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        
        let s = try settings()
        let savedDate = s.achievementUnlockDates["cards_10"]
        #expect(savedDate != nil)
        
        service.refresh()
        let status = service.allAchievements.first(where: { $0.id == "cards_10" })
        #expect(status?.unlockedDate == savedDate)
    }
    
    @Test("refresh: незаблокированные имеют isUnlocked = false и nil дату")
    func refreshUnlockedState() throws {
        service.refresh()
        let cards10 = service.allAchievements.first(where: { $0.id == "cards_10" })
        #expect(cards10?.isUnlocked == false)
        #expect(cards10?.unlockedDate == nil)
    }
    
    // MARK: - consumeRecentlyUnlocked
    
    @Test("consumeRecentlyUnlocked: сбрасывает recentlyUnlocked в nil")
    func consumeResets() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        #expect(service.recentlyUnlocked != nil)
        
        service.consumeRecentlyUnlocked()
        #expect(service.recentlyUnlocked == nil)
    }
    
    @Test("consumeRecentlyUnlocked: на пустом состоянии — не падает")
    func consumeOnEmpty() {
        #expect(service.recentlyUnlocked == nil)
        service.consumeRecentlyUnlocked()
        #expect(service.recentlyUnlocked == nil)
    }
    
    @Test("consumeRecentlyUnlocked: НЕ влияет на unlockedAchievementIDs в settings")
    func consumeDoesNotAffectPersistence() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        
        service.consumeRecentlyUnlocked()
        #expect(try settings().isUnlocked("cards_10") == true)
    }
    
    // MARK: - Персистентность через новый экземпляр
    
    @Test("Новый service на тех же репозиториях видит разблокировки через refresh")
    func persistenceAcrossInstances() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        
        // Новый экземпляр сервиса
        let newService = AchievementsService(
            statsRepository: repos.stats,
            cardRepository: repos.card,
            groupRepository: repos.group
        )
        newService.refresh()
        
        let status = newService.allAchievements.first(where: { $0.id == "cards_10" })
        #expect(status?.isUnlocked == true)
    }
    
    @Test("Новый service: повторный evaluate не разблокирует повторно")
    func noDoubleUnlock() throws {
        for i in 0..<10 {
            _ = try makeCard(origin: "w\(i)")
        }
        _ = service.evaluate()
        
        let newService = AchievementsService(
            statsRepository: repos.stats,
            cardRepository: repos.card,
            groupRepository: repos.group
        )
        let second = newService.evaluate()
        #expect(second.isEmpty)
    }
    
    // MARK: - Пошаговая разблокировка
    
    @Test("Пошаговое добавление карточек: 10 → 50 → 100")
    func stepwiseUnlock() throws {
        for i in 0..<10 { _ = try makeCard(origin: "a\(i)") }
        var unlocked = service.evaluate()
        #expect(unlocked.map(\.id) == ["cards_10"])
        
        for i in 10..<50 { _ = try makeCard(origin: "b\(i)") }
        unlocked = service.evaluate()
        #expect(unlocked.map(\.id) == ["cards_50"])
        
        for i in 50..<100 { _ = try makeCard(origin: "c\(i)") }
        unlocked = service.evaluate()
        #expect(unlocked.map(\.id) == ["cards_100"])
    }
    
    @Test("Много достижений разом: 100 карточек + 10 групп + 25 избранных")
    func manyAtOnce() throws {
        for i in 0..<100 { _ = try makeCard(origin: "w\(i)") }
        for i in 0..<10 { _ = try makeGroup(name: "G\(i)") }
        
        let allCards = try repos.card.fetchAll()
        for card in allCards.prefix(25) {
            try repos.card.toggleFavourite(card)
        }
        
        let unlocked = service.evaluate()
        let ids = Set(unlocked.map(\.id))
        
        #expect(ids.contains("cards_10"))
        #expect(ids.contains("cards_50"))
        #expect(ids.contains("cards_100"))
        #expect(ids.contains("group_1"))
        #expect(ids.contains("group_5"))
        #expect(ids.contains("group_10"))
        #expect(ids.contains("fav_1"))
        #expect(ids.contains("fav_5"))
        #expect(ids.contains("fav_10"))
        #expect(ids.contains("fav_25"))
    }
    
    // MARK: - allAchievements до refresh
    
    @Test("allAchievements: изначально пуст (до первого evaluate/refresh)")
    func allAchievementsInitiallyEmpty() {
        #expect(service.allAchievements.isEmpty)
    }
    
    @Test("evaluate: неявно обновляет allAchievements")
    func evaluateRebuildsStatusList() throws {
        for i in 0..<10 { _ = try makeCard(origin: "w\(i)") }
        _ = service.evaluate()
        
        #expect(service.allAchievements.count == AchievementsCatalog.all.count)
        let cards10 = service.allAchievements.first(where: { $0.id == "cards_10" })
        #expect(cards10?.isUnlocked == true)
    }
    
    // MARK: - Сквозной сценарий
    
    @Test("Полный сценарий: evaluate → consume → refresh → evaluate не даёт дубликата")
    func fullScenario() throws {
        for i in 0..<10 { _ = try makeCard(origin: "w\(i)") }
        
        // 1. Разблокировка
        let unlocked = service.evaluate()
        #expect(unlocked.count == 1)
        #expect(service.recentlyUnlocked?.id == "cards_10")
        
        // 2. UI показал баннер → consume
        service.consumeRecentlyUnlocked()
        #expect(service.recentlyUnlocked == nil)
        
        // 3. Зашли в профиль → refresh
        service.refresh()
        let status = service.allAchievements.first(where: { $0.id == "cards_10" })
        #expect(status?.isUnlocked == true)
        
        // 4. Вернулись, снова evaluate — ничего нового
        let again = service.evaluate()
        #expect(again.isEmpty)
    }
}
