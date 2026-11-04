//
//  SolveGroupKeyTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
@testable import English_Words

@Suite("SolveGroupKey — сериализация")
struct SolveGroupKeyTests {

    @Test("Подборка практики сохраняет все UUID, включая больше пяти карточек")
    func practiceRoundTrip() throws {
        let ids = (0..<12).map { _ in UUID() }
        let key = SolveGroupKey.practice(ids)
        #expect(SolveGroupKey(stringValue: key.stringValue) == key)
        #expect(try JSONDecoder().decode(SolveGroupKey.self, from: JSONEncoder().encode(key)) == key)
        let duplicate = SolveGroupKey.practice([ids[0], ids[0]])
        #expect(SolveGroupKey(stringValue: duplicate.stringValue) == nil)
        #expect(SolveGroupKey(stringValue: "practice_") == nil)
        #expect(SolveGroupKey(stringValue: "practice_bad-uuid") == nil)
    }
    
    @Test("system(.allCards): round-trip через stringValue")
    func systemAllCardsRoundTrip() {
        let key = SolveGroupKey.system(.allCards)
        #expect(key.stringValue == "system_allCards")
        #expect(SolveGroupKey(stringValue: key.stringValue) == key)
    }
    
    @Test("system(.favourites): round-trip")
    func systemFavouritesRoundTrip() {
        let key = SolveGroupKey.system(.favourites)
        #expect(SolveGroupKey(stringValue: key.stringValue) == key)
    }
    
    @Test("user(UUID): round-trip")
    func userRoundTrip() {
        let uuid = UUID()
        let key = SolveGroupKey.user(uuid)
        #expect(key.stringValue == "user_\(uuid.uuidString)")
        #expect(SolveGroupKey(stringValue: key.stringValue) == key)
    }
    
    @Test("srs: stringValue == 'srs'")
    func srsValue() {
        #expect(SolveGroupKey.srs.stringValue == "srs")
        #expect(SolveGroupKey(stringValue: "srs") == .srs)
    }
    
    @Test("init?(stringValue:): неизвестный префикс → nil")
    func unknownPrefixNil() {
        #expect(SolveGroupKey(stringValue: "unknown_thing") == nil)
        #expect(SolveGroupKey(stringValue: "") == nil)
    }
    
    @Test("init?(stringValue:): невалидный UUID → nil")
    func invalidUUIDNil() {
        #expect(SolveGroupKey(stringValue: "user_not-a-uuid") == nil)
    }
    
    @Test("init?(stringValue:): неизвестный SystemGroupType → nil")
    func unknownSystemTypeNil() {
        #expect(SolveGroupKey(stringValue: "system_unknownType") == nil)
    }
    
    @Test("Hashable: одинаковые ключи равны")
    func hashable() {
        let set: Set<SolveGroupKey> = [.srs, .srs, .system(.allCards), .system(.allCards)]
        #expect(set.count == 2)
    }
    
    @Test("Codable: round-trip через JSON")
    func codableRoundTrip() throws {
        let keys: [SolveGroupKey] = [.srs, .system(.allCards), .system(.favourites), .user(UUID())]
        for key in keys {
            let data = try JSONEncoder().encode(key)
            let restored = try JSONDecoder().decode(SolveGroupKey.self, from: data)
            #expect(restored == key)
        }
    }
}
