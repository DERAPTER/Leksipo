//
//  CardRepositoryTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
import SwiftData
@testable import English_Words

@Suite("SwiftDataCardRepository")
@MainActor
struct CardRepositoryTests {
    
    // MARK: - Fixture
    //
    // В Swift Testing struct-suite пересоздаётся для каждого @Test,
    // поэтому каждый тест получает свой in-memory ModelContainer.
    
    let repos: TestContainer.Repositories
    
    init() throws {
        repos = try TestContainer.makeRepositories()
    }
    
    private func makeGroup(name: String = "G") throws -> CardGroup {
        try repos.group.create(name: name)
    }
    
    // MARK: - create
    
    @Test("create: успешное создание увеличивает totalCount")
    func createIncrementsCount() throws {
        #expect(try repos.card.totalCount() == 0)
        _ = try repos.card.create(origin: "hello", translated: "привет", groups: [])
        #expect(try repos.card.totalCount() == 1)
    }
    
    @Test("create: пустой origin → invalidInput")
    func createEmptyOriginThrows() throws {
        #expect(throws: RepositoryError.self) {
            _ = try repos.card.create(origin: "", translated: "привет", groups: [])
        }
    }
    
    @Test("create: пустой translated → invalidInput")
    func createEmptyTranslatedThrows() throws {
        #expect(throws: RepositoryError.self) {
            _ = try repos.card.create(origin: "hello", translated: "", groups: [])
        }
    }
    
    @Test("create: origin из пробелов → invalidInput")
    func createWhitespaceOriginThrows() throws {
        #expect(throws: RepositoryError.self) {
            _ = try repos.card.create(origin: "   ", translated: "привет", groups: [])
        }
    }
    
    @Test("create: обрезает пробелы по краям")
    func createTrimsWhitespace() throws {
        let card = try repos.card.create(
            origin: "  hello  ",
            translated: "  привет  ",
            groups: []
        )
        #expect(card.originWord == "hello")
        #expect(card.translatedWord == "привет")
    }
    
    @Test("create: карточка сразу появляется в переданных группах")
    func createAttachesGroups() throws {
        let g1 = try makeGroup(name: "One")
        let g2 = try makeGroup(name: "Two")
        
        let card = try repos.card.create(origin: "x", translated: "y", groups: [g1, g2])
        
        #expect(card.groups.count == 2)
        #expect(Set(card.groups.map(\.id)) == Set([g1.id, g2.id]))
    }
    
    @Test("create: SRS-поля у новой карточки — дефолтные")
    func createHasDefaultSRSState() throws {
        let card = try repos.card.create(origin: "a", translated: "б", groups: [])
        #expect(card.easeFactor == 2.5)
        #expect(card.intervalDays == 0)
        #expect(card.repetitions == 0)
        #expect(card.nextReviewDate == nil)
        #expect(card.lastReviewDate == nil)
        #expect(card.isNewInSRS == true)
    }
    
    // MARK: - fetchAll / fetch(id:)
    
    @Test("fetchAll: возвращает все созданные карточки")
    func fetchAllReturnsAll() throws {
        _ = try repos.card.create(origin: "a", translated: "1", groups: [])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [])
        _ = try repos.card.create(origin: "c", translated: "3", groups: [])
        
        let all = try repos.card.fetchAll()
        #expect(all.count == 3)
        #expect(Set(all.map(\.originWord)) == ["a", "b", "c"])
    }
    
    @Test("fetchAll: сортировка по dateAdded DESC")
    func fetchAllSortedDesc() throws {
        let ctx = repos.container.mainContext
        let older = Card(origin: "old", translated: "старый",
                         dateAdded: Date().addingTimeInterval(-86400))
        let newer = Card(origin: "new", translated: "новый", dateAdded: .now)
        ctx.insert(older)
        ctx.insert(newer)
        try ctx.save()
        
        let all = try repos.card.fetchAll()
        #expect(all.first?.originWord == "new")
        #expect(all.last?.originWord == "old")
    }
    
    @Test("fetch(id:): находит по id")
    func fetchByID() throws {
        let card = try repos.card.create(origin: "hello", translated: "привет", groups: [])
        let found = try repos.card.fetch(id: card.id)
        #expect(found?.id == card.id)
    }
    
    @Test("fetch(id:): несуществующий id → nil")
    func fetchByIDMissing() throws {
        let found = try repos.card.fetch(id: UUID())
        #expect(found == nil)
    }
    
    // MARK: - fetch(inGroup:) / count(inGroup:)
    
    @Test("fetch(inGroup:) возвращает только карточки этой группы")
    func fetchInGroupFiltersCorrectly() throws {
        let g1 = try makeGroup(name: "G1")
        let g2 = try makeGroup(name: "G2")
        
        _ = try repos.card.create(origin: "a", translated: "1", groups: [g1])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [g1, g2])
        _ = try repos.card.create(origin: "c", translated: "3", groups: [g2])
        _ = try repos.card.create(origin: "d", translated: "4", groups: [])
        
        let inG1 = try repos.card.fetch(inGroup: g1.id)
        let inG2 = try repos.card.fetch(inGroup: g2.id)
        
        #expect(Set(inG1.map(\.originWord)) == ["a", "b"])
        #expect(Set(inG2.map(\.originWord)) == ["b", "c"])
    }
    
    @Test("count(inGroup:) совпадает с размером fetch(inGroup:)")
    func countInGroupMatchesFetch() throws {
        let g = try makeGroup(name: "G")
        _ = try repos.card.create(origin: "a", translated: "1", groups: [g])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [g])
        
        #expect(try repos.card.count(inGroup: g.id) == 2)
        #expect(try repos.card.fetch(inGroup: g.id).count == 2)
    }
    
    @Test("count(inGroup:) для пустой группы → 0")
    func countInEmptyGroup() throws {
        let g = try makeGroup(name: "Empty")
        #expect(try repos.card.count(inGroup: g.id) == 0)
    }
    
    // MARK: - fetchFavourites / favouritesCount
    
    @Test("fetchFavourites возвращает только избранные")
    func fetchFavourites() throws {
        let a = try repos.card.create(origin: "a", translated: "1", groups: [])
        let _ = try repos.card.create(origin: "b", translated: "2", groups: [])
        
        try repos.card.toggleFavourite(a)
        
        let favs = try repos.card.fetchFavourites()
        #expect(favs.count == 1)
        #expect(favs.first?.id == a.id)
    }
    
    @Test("favouritesCount синхронизирован с toggleFavourite")
    func favouritesCountSync() throws {
        let a = try repos.card.create(origin: "a", translated: "1", groups: [])
        #expect(try repos.card.favouritesCount() == 0)
        
        try repos.card.toggleFavourite(a)
        #expect(try repos.card.favouritesCount() == 1)
        
        try repos.card.toggleFavourite(a)
        #expect(try repos.card.favouritesCount() == 0)
    }
    
    // MARK: - search
    
    @Test("search: находит по origin (регистронезависимо)")
    func searchByOriginCaseInsensitive() throws {
        _ = try repos.card.create(origin: "Hello", translated: "привет", groups: [])
        _ = try repos.card.create(origin: "World", translated: "мир", groups: [])
        
        let result = try repos.card.search("hello")
        #expect(result.count == 1)
        #expect(result.first?.originWord == "Hello")
    }
    
    @Test("search: находит по translated")
    func searchByTranslation() throws {
        _ = try repos.card.create(origin: "hello", translated: "Привет", groups: [])
        _ = try repos.card.create(origin: "world", translated: "мир", groups: [])
        
        let result = try repos.card.search("прив")
        #expect(result.count == 1)
        #expect(result.first?.originWord == "hello")
    }
    
    @Test("search: пустой запрос возвращает всё")
    func searchEmptyReturnsAll() throws {
        _ = try repos.card.create(origin: "a", translated: "1", groups: [])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [])
        
        #expect(try repos.card.search("").count == 2)
        #expect(try repos.card.search("   ").count == 2)
    }
    
    @Test("search: нет совпадений → пусто")
    func searchNoMatches() throws {
        _ = try repos.card.create(origin: "hello", translated: "привет", groups: [])
        #expect(try repos.card.search("xyz").isEmpty)
    }
    
    // MARK: - update
    
    @Test("update: обновляет слова и группы")
    func updateChangesWordsAndGroups() throws {
        let g1 = try makeGroup(name: "G1")
        let g2 = try makeGroup(name: "G2")
        
        let card = try repos.card.create(origin: "a", translated: "1", groups: [g1])
        try repos.card.update(card, origin: "b", translated: "2", groups: [g2])
        
        #expect(card.originWord == "b")
        #expect(card.translatedWord == "2")
        #expect(card.groups.map(\.id) == [g2.id])
    }
    
    @Test("update: обрезает пробелы")
    func updateTrimsWhitespace() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        try repos.card.update(card, origin: "  b  ", translated: "  2  ", groups: [])
        #expect(card.originWord == "b")
        #expect(card.translatedWord == "2")
    }
    
    @Test("update: пустое поле → invalidInput")
    func updateEmptyThrows() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        #expect(throws: RepositoryError.self) {
            try repos.card.update(card, origin: "", translated: "1", groups: [])
        }
    }
    
    // MARK: - delete
    
    @Test("delete: уменьшает totalCount")
    func deleteDecrementsCount() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        try repos.card.delete(card)
        #expect(try repos.card.totalCount() == 0)
    }
    
    @Test("delete: удаляет из всех групп (many-to-many)")
    func deleteRemovesFromAllGroups() throws {
        let g1 = try makeGroup(name: "G1")
        let g2 = try makeGroup(name: "G2")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [g1, g2])
        
        try repos.card.delete(card)
        
        #expect(try repos.card.count(inGroup: g1.id) == 0)
        #expect(try repos.card.count(inGroup: g2.id) == 0)
    }
    
    // MARK: - recordAnswer
    
    @Test("recordAnswer(correct: true) инкрементирует correctCount")
    func recordAnswerCorrect() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        try repos.card.recordAnswer(card, correct: true)
        try repos.card.recordAnswer(card, correct: true)
        #expect(card.correctCount == 2)
        #expect(card.wrongCount == 0)
        #expect(card.totalAttempts == 2)
    }
    
    @Test("recordAnswer(correct: false) инкрементирует wrongCount")
    func recordAnswerWrong() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        try repos.card.recordAnswer(card, correct: false)
        #expect(card.correctCount == 0)
        #expect(card.wrongCount == 1)
        #expect(card.totalAttempts == 1)
    }
    
    @Test("successRate считает корректно")
    func successRateCalculation() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        #expect(card.successRate == 0)
        
        try repos.card.recordAnswer(card, correct: true)
        try repos.card.recordAnswer(card, correct: true)
        try repos.card.recordAnswer(card, correct: false)
        try repos.card.recordAnswer(card, correct: false)
        #expect(abs(card.successRate - 0.5) < 1e-9)
    }
    
    // MARK: - exists
    
    @Test("exists: одинаковая пара word+translation → true")
    func existsReturnsTrue() throws {
        _ = try repos.card.create(origin: "hello", translated: "привет", groups: [])
        #expect(try repos.card.exists(origin: "hello", translated: "привет", excluding: nil) == true)
    }
    
    @Test("exists: регистронезависим")
    func existsCaseInsensitive() throws {
        _ = try repos.card.create(origin: "Hello", translated: "Привет", groups: [])
        #expect(try repos.card.exists(origin: "hello", translated: "привет", excluding: nil) == true)
    }
    
    @Test("exists: excluding убирает саму карточку из проверки")
    func existsExcludingSelf() throws {
        let card = try repos.card.create(origin: "hello", translated: "привет", groups: [])
        #expect(try repos.card.exists(origin: "hello", translated: "привет", excluding: card.id) == false)
    }
    
    @Test("exists: нет совпадений → false")
    func existsNoMatch() throws {
        _ = try repos.card.create(origin: "hello", translated: "привет", groups: [])
        #expect(try repos.card.exists(origin: "world", translated: "мир", excluding: nil) == false)
    }
    
    // MARK: - SRS: fetchDueToday / dueTodayCount
    
    @Test("fetchDueToday: новые карточки попадают в результат")
    func fetchDueTodayIncludesNew() throws {
        _ = try repos.card.create(origin: "a", translated: "1", groups: [])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [])
        
        let due = try repos.card.fetchDueToday(on: .now, newCardsLimit: 10)
        #expect(due.count == 2)
    }
    
    @Test("fetchDueToday: уважает лимит новых карточек")
    func fetchDueTodayRespectsNewLimit() throws {
        for i in 0..<5 {
            _ = try repos.card.create(origin: "w\(i)", translated: "п\(i)", groups: [])
        }
        let due = try repos.card.fetchDueToday(on: .now, newCardsLimit: 2)
        #expect(due.count == 2)
    }
    
    @Test("fetchDueToday: newCardsLimit=0 не возвращает новых")
    func fetchDueTodayZeroNewLimit() throws {
        _ = try repos.card.create(origin: "a", translated: "1", groups: [])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [])
        
        let due = try repos.card.fetchDueToday(on: .now, newCardsLimit: 0)
        #expect(due.isEmpty)
    }
    
    @Test("fetchDueToday: карточки с истёкшим nextReviewDate попадают в результат")
    func fetchDueTodayIncludesOverdue() throws {
        let ctx = repos.container.mainContext
        let card = Card(origin: "old", translated: "старый")
        card.lastReviewDate = Date().addingTimeInterval(-86400 * 10)
        card.nextReviewDate = Date().addingTimeInterval(-86400 * 2)
        card.intervalDays = 10
        card.repetitions = 3
        ctx.insert(card)
        try ctx.save()
        
        let due = try repos.card.fetchDueToday(on: .now, newCardsLimit: 0)
        #expect(due.count == 1)
        #expect(due.first?.id == card.id)
    }
    
    @Test("fetchDueToday: карточки с будущим nextReviewDate не попадают")
    func fetchDueTodayExcludesFuture() throws {
        let ctx = repos.container.mainContext
        let card = Card(origin: "future", translated: "будущее")
        card.lastReviewDate = .now
        card.nextReviewDate = Date().addingTimeInterval(86400 * 5)
        card.intervalDays = 5
        card.repetitions = 2
        ctx.insert(card)
        try ctx.save()
        
        let due = try repos.card.fetchDueToday(on: .now, newCardsLimit: 0)
        #expect(due.isEmpty)
    }
    
    @Test("fetchDueToday: due идут раньше новых в результате")
    func fetchDueTodayOrderDueBeforeNew() throws {
        let ctx = repos.container.mainContext
        
        // Новая карточка
        _ = try repos.card.create(origin: "new", translated: "новая", groups: [])
        
        // Просроченная
        let overdue = Card(origin: "overdue", translated: "просрочена")
        overdue.lastReviewDate = Date().addingTimeInterval(-86400)
        overdue.nextReviewDate = Date().addingTimeInterval(-3600)
        overdue.intervalDays = 1
        overdue.repetitions = 1
        ctx.insert(overdue)
        try ctx.save()
        
        let due = try repos.card.fetchDueToday(on: .now, newCardsLimit: 10)
        #expect(due.count == 2)
        #expect(due.first?.id == overdue.id)
        #expect(due.last?.originWord == "new")
    }
    
    @Test("dueTodayCount совпадает с размером fetchDueToday")
    func dueTodayCountMatchesFetch() throws {
        _ = try repos.card.create(origin: "a", translated: "1", groups: [])
        _ = try repos.card.create(origin: "b", translated: "2", groups: [])
        
        let count = try repos.card.dueTodayCount(on: .now, newCardsLimit: 10)
        let fetched = try repos.card.fetchDueToday(on: .now, newCardsLimit: 10)
        #expect(count == fetched.count)
    }
    
    // MARK: - SRS: recordSRSReview
    
    @Test("recordSRSReview(q=4): обновляет SRS-поля и correctCount")
    func recordSRSReviewCorrect() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        let date = Date()
        
        try repos.card.recordSRSReview(card, quality: 4, on: date)
        
        #expect(card.intervalDays == 1)
        #expect(card.repetitions == 1)
        #expect(abs(card.easeFactor - 2.5) < 1e-9)
        #expect(card.nextReviewDate != nil)
        #expect(card.lastReviewDate == date)
        #expect(card.correctCount == 1)
        #expect(card.wrongCount == 0)
    }
    
    @Test("recordSRSReview(q=1): сбрасывает reps, ставит interval=1, инкрементирует wrongCount")
    func recordSRSReviewWrong() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        // эмулируем «уже изучалась»
        card.repetitions = 5
        card.intervalDays = 30
        try repos.container.mainContext.save()
        
        try repos.card.recordSRSReview(card, quality: 1, on: .now)
        
        #expect(card.intervalDays == 1)
        #expect(card.repetitions == 0)
        #expect(card.correctCount == 0)
        #expect(card.wrongCount == 1)
    }
    
    @Test("recordSRSReview: nextReviewDate нормализован к началу дня")
    func recordSRSReviewNormalizesNextDate() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        try repos.card.recordSRSReview(card, quality: 4, on: .now)
        
        let next = try #require(card.nextReviewDate)
        let cal = Calendar.current
        #expect(next == cal.startOfDay(for: next))
    }
    
    @Test("После recordSRSReview карточка перестаёт быть новой")
    func recordSRSReviewMakesCardNotNew() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        #expect(card.isNewInSRS == true)
        try repos.card.recordSRSReview(card, quality: 4, on: .now)
        #expect(card.isNewInSRS == false)
    }
    
    @Test("После recordSRSReview(q=5) карточка не попадает в due до наступления nextReviewDate")
    func recordSRSReviewPostponesCard() throws {
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        try repos.card.recordSRSReview(card, quality: 5, on: .now)
        
        // Сразу после review — карточка ещё not due (nextReviewDate = завтра)
        let dueNow = try repos.card.fetchDueToday(on: .now, newCardsLimit: 0)
        #expect(dueNow.isEmpty)
        
        // А через 2 дня — уже due
        let future = Date().addingTimeInterval(86400 * 2)
        let dueLater = try repos.card.fetchDueToday(on: future, newCardsLimit: 0)
        #expect(dueLater.count == 1)
    }
}
