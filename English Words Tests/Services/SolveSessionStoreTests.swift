//
//  SolveSessionStoreTests.swift
//  English Words Tests
//
//  Created by Егор Халиков on 06.10.2026.
//

import Testing
import Foundation
@testable import English_Words

@Suite("SolveSessionStore — хранение сессий в UserDefaults")
@MainActor
struct SolveSessionStoreTests {
    
    // MARK: - Fixture
    
    let defaults: UserDefaults
    let store: SolveSessionStore
    let suiteName: String
    
    init() {
        suiteName = "SolveSessionStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        store = SolveSessionStore(defaults: defaults)
    }
    
    // MARK: - Helpers
    
    private func makeSession(
        key: SolveGroupKey = .system(.allCards),
        cardIDs: [UUID] = []
    ) -> SolveSession {
        SolveSession(groupKey: key, cardIDs: cardIDs)
    }
    
    // MARK: - load: пустое хранилище
    
    @Test("load: пустой store → nil")
    func loadEmptyStore() throws {
        #expect(try store.load(for: .system(.allCards)) == nil)
        #expect(try store.load(for: .srs) == nil)
        #expect(try store.load(for: .user(UUID())) == nil)
    }
    
    // MARK: - save + load
    
    @Test("save → load возвращает ту же сессию")
    func saveAndLoadRoundTrip() throws {
        let session = makeSession(cardIDs: [UUID(), UUID()])
        try store.save(session, for: .system(.allCards))
        
        let loaded = try store.load(for: .system(.allCards))
        #expect(loaded == session)
    }
    
    @Test("save для SRS-ключа работает")
    func saveSRS() throws {
        let session = makeSession(key: .srs, cardIDs: [UUID()])
        try store.save(session, for: .srs)
        #expect(try store.load(for: .srs) == session)
    }
    
    @Test("save для user-ключа с UUID работает")
    func saveUserKey() throws {
        let userID = UUID()
        let session = makeSession(key: .user(userID), cardIDs: [UUID()])
        try store.save(session, for: .user(userID))
        #expect(try store.load(for: .user(userID)) == session)
    }
    
    @Test("save: повторное сохранение для того же ключа перезаписывает")
    func saveOverwrites() throws {
        var session = makeSession(cardIDs: [UUID(), UUID()])
        try store.save(session, for: .system(.allCards))
        
        session.markCorrect()
        try store.save(session, for: .system(.allCards))
        
        let loaded = try store.load(for: .system(.allCards))
        #expect(loaded?.successIDs.count == 1)
        #expect(loaded == session)
    }
    
    @Test("save: разные ключи хранятся независимо")
    func saveMultipleKeysIndependently() throws {
        let s1 = makeSession(key: .system(.allCards), cardIDs: [UUID()])
        let s2 = makeSession(key: .system(.favourites), cardIDs: [UUID(), UUID()])
        let s3 = makeSession(key: .srs, cardIDs: [UUID(), UUID(), UUID()])
        
        try store.save(s1, for: .system(.allCards))
        try store.save(s2, for: .system(.favourites))
        try store.save(s3, for: .srs)
        
        #expect(try store.load(for: .system(.allCards)) == s1)
        #expect(try store.load(for: .system(.favourites)) == s2)
        #expect(try store.load(for: .srs) == s3)
    }
    
    @Test("save: сессия с прогрессом (success/fail) сохраняется и восстанавливается")
    func saveWithProgress() throws {
        var session = makeSession(cardIDs: [UUID(), UUID(), UUID()])
        session.markCorrect()
        session.markWrong()
        
        try store.save(session, for: .srs)
        let loaded = try store.load(for: .srs)
        
        #expect(loaded?.successIDs == session.successIDs)
        #expect(loaded?.failIDs == session.failIDs)
        #expect(loaded?.unsolvedIDs == session.unsolvedIDs)
    }
    
    // MARK: - clear
    
    @Test("clear: удаляет только указанный ключ")
    func clearRemovesOneKey() throws {
        try store.save(makeSession(), for: .system(.allCards))
        try store.save(makeSession(), for: .srs)
        
        try store.clear(for: .system(.allCards))
        
        #expect(try store.load(for: .system(.allCards)) == nil)
        #expect(try store.load(for: .srs) != nil)
    }
    
    @Test("clear: несуществующий ключ — no-op")
    func clearNonExistentKey() throws {
        try store.save(makeSession(), for: .srs)
        try store.clear(for: .system(.allCards))
        #expect(try store.load(for: .srs) != nil)
    }
    
    @Test("clear: на пустом store — не падает")
    func clearEmptyStore() throws {
        try store.clear(for: .system(.allCards))
        #expect(try store.load(for: .system(.allCards)) == nil)
    }
    
    // MARK: - clearAll
    
    @Test("clearAll: удаляет все сессии")
    func clearAllRemovesEverything() throws {
        try store.save(makeSession(), for: .system(.allCards))
        try store.save(makeSession(), for: .system(.favourites))
        try store.save(makeSession(key: .srs, cardIDs: [UUID()]), for: .srs)
        
        try store.clearAll()
        
        #expect(try store.load(for: .system(.allCards)) == nil)
        #expect(try store.load(for: .system(.favourites)) == nil)
        #expect(try store.load(for: .srs) == nil)
        #expect(try store.allSessionKeys().isEmpty)
    }
    
    @Test("clearAll: на пустом store — не падает")
    func clearAllEmpty() throws {
        try store.clearAll()
        #expect(try store.allSessionKeys().isEmpty)
    }
    
    // MARK: - allSessionKeys
    
    @Test("allSessionKeys: пустой store → пустое множество")
    func allSessionKeysEmpty() throws {
        #expect(try store.allSessionKeys().isEmpty)
    }
    
    @Test("allSessionKeys: возвращает все сохранённые ключи")
    func allSessionKeysReturnsAll() throws {
        let userID = UUID()
        try store.save(makeSession(key: .system(.allCards)), for: .system(.allCards))
        try store.save(makeSession(key: .system(.favourites)), for: .system(.favourites))
        try store.save(makeSession(key: .user(userID)), for: .user(userID))
        try store.save(makeSession(key: .srs), for: .srs)
        
        let keys = try store.allSessionKeys()
        #expect(keys.count == 4)
        #expect(keys.contains(.system(.allCards)))
        #expect(keys.contains(.system(.favourites)))
        #expect(keys.contains(.user(userID)))
        #expect(keys.contains(.srs))
    }
    
    @Test("allSessionKeys: после clear одного — остальные на месте")
    func allSessionKeysAfterClear() throws {
        try store.save(makeSession(), for: .system(.allCards))
        try store.save(makeSession(key: .srs), for: .srs)
        
        try store.clear(for: .srs)
        
        let keys = try store.allSessionKeys()
        #expect(keys == [.system(.allCards)])
    }
    
    // MARK: - Изоляция между suite
    
    @Test("Разные UserDefaults suite — изолированные хранилища")
    func differentSuitesAreIsolated() throws {
        let otherSuiteName = "SolveSessionStoreTests-\(UUID().uuidString)"
        let otherDefaults = UserDefaults(suiteName: otherSuiteName)!
        defer { otherDefaults.removePersistentDomain(forName: otherSuiteName) }
        
        let otherStore = SolveSessionStore(defaults: otherDefaults)
        
        try store.save(makeSession(key: .srs), for: .srs)
        
        // В другом suite — пусто
        #expect(try otherStore.load(for: .srs) == nil)
    }
    
    // MARK: - Персистентность между инстансами
    
    @Test("Новый store на том же suite читает сохранённые данные")
    func persistsAcrossInstances() throws {
        let session = makeSession(cardIDs: [UUID(), UUID()])
        try store.save(session, for: .system(.allCards))
        
        // Создаём новый store на том же suite
        let anotherStore = SolveSessionStore(defaults: defaults)
        #expect(try anotherStore.load(for: .system(.allCards)) == session)
    }
    
    // MARK: - Повреждённые данные
    
    @Test("Повреждённые данные сообщают ошибку и не перезаписываются")
    func corruptedDataGraceful() throws {
        let garbage = Data("not-a-valid-json".utf8)
        defaults.set(garbage, forKey: "solve_sessions_v1")
        #expect(throws: (any Error).self) { try store.load(for: .srs) }
        #expect(throws: (any Error).self) { try store.save(makeSession(), for: .srs) }
        #expect(defaults.data(forKey: "solve_sessions_v1") == garbage)
    }

    @Test("Данные неизвестного формата в UserDefaults (не Data) → не падает")
    func wrongTypeGraceful() throws {
        // Кладём строку вместо Data
        defaults.set("just-a-string", forKey: "solve_sessions_v1")
        
        #expect(try store.load(for: .system(.allCards)) == nil)
        #expect(try store.allSessionKeys().isEmpty)
    }
    
    // MARK: - Сквозные сценарии
    
    @Test("Сценарий: сохранили → отметили карточку → перезаписали → прочитали")
    func markAndPersist() throws {
        let cardIDs = [UUID(), UUID(), UUID()]
        var session = makeSession(key: .srs, cardIDs: cardIDs)
        try store.save(session, for: .srs)
        
        session.markCorrect()
        try store.save(session, for: .srs)
        
        let loaded = try store.load(for: .srs)
        #expect(loaded?.successIDs.count == 1)
        #expect(loaded?.unsolvedIDs.count == 2)
        #expect(loaded?.totalCount == 3)
    }
    
    @Test("Сценарий: 4 разных сессии + clearAll → всё чисто")
    func multiSessionThenClearAll() throws {
        let keys: [SolveGroupKey] = [
            .system(.allCards),
            .system(.favourites),
            .user(UUID()),
            .srs
        ]
        
        for key in keys {
            try store.save(makeSession(key: key, cardIDs: [UUID()]), for: key)
        }
        #expect(try store.allSessionKeys().count == 4)
        
        try store.clearAll()
        #expect(try store.allSessionKeys().isEmpty)
        
        for key in keys {
            #expect(try store.load(for: key) == nil)
        }
    }
}
