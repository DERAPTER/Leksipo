//
//  GroupRepositoryTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
import SwiftData
@testable import English_Words

@Suite("SwiftDataGroupRepository")
@MainActor
struct GroupRepositoryTests {
    
    let repos: TestContainer.Repositories
    
    init() throws {
        repos = try TestContainer.makeRepositories()
    }
    
    /// Вспомогательный метод: создать системную группу напрямую,
    /// минуя репозиторий (он таких не создаёт).
    @discardableResult
    private func insertSystemGroup(type: SystemGroupType) throws -> CardGroup {
        let group = CardGroup(name: "sys", systemType: type)
        repos.container.mainContext.insert(group)
        try repos.container.mainContext.save()
        return group
    }
    
    // MARK: - create
    
    @Test("create: базовая группа создаётся и появляется в fetchUserGroups")
    func createAppearsInFetch() throws {
        let g = try repos.group.create(name: "Animals")
        let all = try repos.group.fetchUserGroups()
        #expect(all.contains(where: { $0.id == g.id }))
        #expect(all.count == 1)
    }
    
    @Test("create: пустое имя → invalidInput")
    func createEmptyThrows() throws {
        #expect(throws: RepositoryError.self) {
            _ = try repos.group.create(name: "")
        }
    }
    
    @Test("create: имя из пробелов → invalidInput")
    func createWhitespaceThrows() throws {
        #expect(throws: RepositoryError.self) {
            _ = try repos.group.create(name: "   ")
        }
    }
    
    @Test("create: тримминг пробелов по краям")
    func createTrims() throws {
        let g = try repos.group.create(name: "  Animals  ")
        #expect(g.name == "Animals")
    }
    
    @Test("create: дубликат имени → invalidInput")
    func createDuplicateThrows() throws {
        _ = try repos.group.create(name: "Animals")
        #expect(throws: RepositoryError.self) {
            _ = try repos.group.create(name: "Animals")
        }
    }
    
    @Test("create: дубликат без учёта регистра → invalidInput")
    func createDuplicateCaseInsensitive() throws {
        _ = try repos.group.create(name: "Animals")
        #expect(throws: RepositoryError.self) {
            _ = try repos.group.create(name: "animals")
        }
    }
    
    @Test("create: orderIndex растёт по мере создания")
    func createOrderIndexIncrements() throws {
        let g1 = try repos.group.create(name: "A")
        let g2 = try repos.group.create(name: "B")
        let g3 = try repos.group.create(name: "C")
        
        #expect(g1.orderIndex == 0)
        #expect(g2.orderIndex == 1)
        #expect(g3.orderIndex == 2)
    }
    
    @Test("create: systemTypeRaw у пользовательской группы = nil")
    func createUserGroupHasNoSystemType() throws {
        let g = try repos.group.create(name: "A")
        #expect(g.systemTypeRaw == nil)
        #expect(g.isSystem == false)
    }
    
    // MARK: - fetchUserGroups
    
    @Test("fetchUserGroups: пустая база → пусто")
    func fetchUserGroupsEmpty() throws {
        #expect(try repos.group.fetchUserGroups().isEmpty)
    }
    
    @Test("fetchUserGroups: не возвращает системные группы")
    func fetchUserGroupsExcludesSystem() throws {
        try insertSystemGroup(type: .allCards)
        try insertSystemGroup(type: .favourites)
        _ = try repos.group.create(name: "User1")
        
        let all = try repos.group.fetchUserGroups()
        #expect(all.count == 1)
        #expect(all.first?.name == "User1")
    }
    
    @Test("fetchUserGroups: сортировка по orderIndex ascending")
    func fetchUserGroupsSortedByOrderIndex() throws {
        _ = try repos.group.create(name: "First")
        _ = try repos.group.create(name: "Second")
        _ = try repos.group.create(name: "Third")
        
        let all = try repos.group.fetchUserGroups()
        #expect(all.map(\.name) == ["First", "Second", "Third"])
    }
    
    // MARK: - fetch(id:)
    
    @Test("fetch(id:): находит по id")
    func fetchByID() throws {
        let g = try repos.group.create(name: "X")
        #expect(try repos.group.fetch(id: g.id)?.id == g.id)
    }
    
    @Test("fetch(id:): несуществующий → nil")
    func fetchByIDMissing() throws {
        #expect(try repos.group.fetch(id: UUID()) == nil)
    }
    
    @Test("fetch(id:): системную группу тоже находит")
    func fetchByIDSystemGroup() throws {
        let sys = try insertSystemGroup(type: .allCards)
        let found = try repos.group.fetch(id: sys.id)
        #expect(found?.id == sys.id)
        #expect(found?.isSystem == true)
    }
    
    // MARK: - userGroupsCount
    
    @Test("userGroupsCount: считает только пользовательские")
    func userGroupsCountExcludesSystem() throws {
        try insertSystemGroup(type: .allCards)
        _ = try repos.group.create(name: "A")
        _ = try repos.group.create(name: "B")
        
        #expect(try repos.group.userGroupsCount() == 2)
    }
    
    @Test("userGroupsCount: совпадает с размером fetchUserGroups")
    func userGroupsCountMatchesFetch() throws {
        _ = try repos.group.create(name: "A")
        _ = try repos.group.create(name: "B")
        #expect(try repos.group.userGroupsCount() == (try repos.group.fetchUserGroups()).count)
    }
    
    // MARK: - rename
    
    @Test("rename: переименовывает пользовательскую группу")
    func renameSuccess() throws {
        let g = try repos.group.create(name: "Old")
        try repos.group.rename(g, to: "New")
        #expect(g.name == "New")
    }
    
    @Test("rename: тримминг")
    func renameTrims() throws {
        let g = try repos.group.create(name: "Old")
        try repos.group.rename(g, to: "  New  ")
        #expect(g.name == "New")
    }
    
    @Test("rename: пустое → invalidInput")
    func renameEmptyThrows() throws {
        let g = try repos.group.create(name: "Old")
        #expect(throws: RepositoryError.self) {
            try repos.group.rename(g, to: "")
        }
    }
    
    @Test("rename: дубликат чужого имени → invalidInput")
    func renameDuplicateThrows() throws {
        _ = try repos.group.create(name: "A")
        let g = try repos.group.create(name: "B")
        #expect(throws: RepositoryError.self) {
            try repos.group.rename(g, to: "A")
        }
    }
    
    @Test("rename: на своё же имя — не падает")
    func renameToOwnName() throws {
        let g = try repos.group.create(name: "A")
        try repos.group.rename(g, to: "A")
        #expect(g.name == "A")
    }
    
    @Test("rename: системную группу → invalidInput")
    func renameSystemThrows() throws {
        let sys = try insertSystemGroup(type: .allCards)
        #expect(throws: RepositoryError.self) {
            try repos.group.rename(sys, to: "Renamed")
        }
    }
    
    // MARK: - delete
    
    @Test("delete: удаляет пользовательскую группу")
    func deleteSuccess() throws {
        let g = try repos.group.create(name: "A")
        try repos.group.delete(g)
        #expect(try repos.group.fetchUserGroups().isEmpty)
    }
    
    @Test("delete: системную → invalidInput")
    func deleteSystemThrows() throws {
        let sys = try insertSystemGroup(type: .allCards)
        #expect(throws: RepositoryError.self) {
            try repos.group.delete(sys)
        }
    }
    
    @Test("delete: карточки остаются, удаляются только связи")
    func deleteKeepsCards() throws {
        let g = try repos.group.create(name: "A")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [g])
        
        try repos.group.delete(g)
        
        // Карточка всё ещё существует
        #expect(try repos.card.totalCount() == 1)
        // И больше не привязана к удалённой группе
        #expect(card.groups.isEmpty)
    }
    
    // MARK: - addCard / removeCard
    
    @Test("addCard: добавляет связь")
    func addCardSuccess() throws {
        let g = try repos.group.create(name: "A")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        
        try repos.group.addCard(card, to: g)
        
        #expect(card.groups.contains(where: { $0.id == g.id }))
        #expect(try repos.card.count(inGroup: g.id) == 1)
    }
    
    @Test("addCard: повторное добавление — no-op (не дублирует)")
    func addCardTwiceNoDuplicate() throws {
        let g = try repos.group.create(name: "A")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        
        try repos.group.addCard(card, to: g)
        try repos.group.addCard(card, to: g)
        
        #expect(card.groups.count == 1)
    }
    
    @Test("removeCard: удаляет связь")
    func removeCardSuccess() throws {
        let g = try repos.group.create(name: "A")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [g])
        
        try repos.group.removeCard(card, from: g)
        
        #expect(card.groups.isEmpty)
        #expect(try repos.card.count(inGroup: g.id) == 0)
    }
    
    @Test("removeCard: если связи нет — ничего не ломается")
    func removeCardNotInGroupNoCrash() throws {
        let g = try repos.group.create(name: "A")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [])
        
        try repos.group.removeCard(card, from: g)
        
        #expect(card.groups.isEmpty)
    }
    
    @Test("removeCard: не затрагивает другие группы")
    func removeCardKeepsOtherGroups() throws {
        let g1 = try repos.group.create(name: "G1")
        let g2 = try repos.group.create(name: "G2")
        let card = try repos.card.create(origin: "a", translated: "1", groups: [g1, g2])
        
        try repos.group.removeCard(card, from: g1)
        
        #expect(card.groups.count == 1)
        #expect(card.groups.first?.id == g2.id)
    }
    
    // MARK: - nameExists
    
    @Test("nameExists: точное совпадение → true")
    func nameExistsExact() throws {
        _ = try repos.group.create(name: "Animals")
        #expect(try repos.group.nameExists("Animals", excluding: nil) == true)
    }
    
    @Test("nameExists: регистронезависим")
    func nameExistsCaseInsensitive() throws {
        _ = try repos.group.create(name: "Animals")
        #expect(try repos.group.nameExists("animals", excluding: nil) == true)
    }
    
    @Test("nameExists: excluding убирает саму себя")
    func nameExistsExcludingSelf() throws {
        let g = try repos.group.create(name: "Animals")
        #expect(try repos.group.nameExists("Animals", excluding: g.id) == false)
    }
    
    @Test("nameExists: нет совпадений → false")
    func nameExistsNoMatch() throws {
        _ = try repos.group.create(name: "Animals")
        #expect(try repos.group.nameExists("Plants", excluding: nil) == false)
    }
    
    @Test("nameExists: пустая база → false")
    func nameExistsEmptyBase() throws {
        #expect(try repos.group.nameExists("X", excluding: nil) == false)
    }
    
    // MARK: - Мульти-тест целостности
    
    @Test("create → rename → addCard → removeCard → delete — не падает")
    func fullLifecycle() throws {
        let g = try repos.group.create(name: "Animals")
        try repos.group.rename(g, to: "Creatures")
        
        let card = try repos.card.create(origin: "cat", translated: "кот", groups: [])
        try repos.group.addCard(card, to: g)
        #expect(try repos.card.count(inGroup: g.id) == 1)
        
        try repos.group.removeCard(card, from: g)
        #expect(try repos.card.count(inGroup: g.id) == 0)
        
        try repos.group.delete(g)
        #expect(try repos.group.userGroupsCount() == 0)
    }
    
    @Test("Порядок групп сохраняется после удаления средней")
    func orderIndexAfterDeletion() throws {
        let g1 = try repos.group.create(name: "A") // 0
        let g2 = try repos.group.create(name: "B") // 1
        let g3 = try repos.group.create(name: "C") // 2
        
        try repos.group.delete(g2)
        
        let remaining = try repos.group.fetchUserGroups()
        #expect(remaining.map(\.id) == [g1.id, g3.id])
        // orderIndex не пересчитывается — остаётся 0 и 2
        #expect(remaining.map(\.orderIndex) == [0, 2])
    }
}
