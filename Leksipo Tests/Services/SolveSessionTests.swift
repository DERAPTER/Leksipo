//
//  SolveSessionTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
@testable import English_Words

@Suite("SolveSession — модель сессии нарешивания")
struct SolveSessionTests {
    
    // MARK: - Helpers
    
    private func ids(_ n: Int) -> [UUID] {
        (0..<n).map { _ in UUID() }
    }
    
    // MARK: - Инициализация
    
    @Test("init: все карточки попадают в unsolvedIDs")
    func initPutsAllIntoUnsolved() {
        let cardIDs = ids(5)
        let session = SolveSession(groupKey: .system(.allCards), cardIDs: cardIDs)
        #expect(session.unsolvedIDs.count == 5)
        #expect(Set(session.unsolvedIDs) == Set(cardIDs))
        #expect(session.successIDs.isEmpty)
        #expect(session.failIDs.isEmpty)
    }
    
    @Test("init: порядок unsolvedIDs перемешан (не совпадает с исходным для 20+ карточек)")
    func initShufflesOrder() {
        let cardIDs = ids(50)
        let session = SolveSession(groupKey: .system(.allCards), cardIDs: cardIDs)
        #expect(session.unsolvedIDs != cardIDs)
    }
    
    @Test("init: группа сохраняется в groupKeyString и восстанавливается через groupKey")
    func initPersistsKey() {
        let session = SolveSession(groupKey: .user(UUID()), cardIDs: [])
        #expect(session.groupKey != nil)
    }
    
    @Test("init: SRS-ключ корректно сохраняется")
    func initSRSKey() {
        let session = SolveSession(groupKey: .srs, cardIDs: [])
        #expect(session.groupKeyString == "srs")
        if case .srs = session.groupKey { } else {
            Issue.record("groupKey должен быть .srs")
        }
    }
    
    // MARK: - Counts
    
    @Test("totalCount = unsolved + success + fail")
    func totalCount() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(4))
        session.markCorrect()
        session.markWrong()
        #expect(session.totalCount == 4)
    }
    
    @Test("solvedCount = success + fail")
    func solvedCount() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(4))
        session.markCorrect()
        session.markCorrect()
        session.markWrong()
        #expect(session.solvedCount == 3)
    }
    
    @Test("currentCardID — первый в очереди")
    func currentCardID() {
        let session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(3))
        #expect(session.currentCardID == session.unsolvedIDs.first)
    }
    
    @Test("currentCardID == nil, когда очередь пуста")
    func currentCardIDEmpty() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(1))
        session.markCorrect()
        #expect(session.currentCardID == nil)
    }
    
    // MARK: - State
    
    @Test("isSolving true, пока очередь не пуста")
    func isSolving() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(2))
        #expect(session.isSolving == true)
        session.markCorrect()
        #expect(session.isSolving == true)
        session.markCorrect()
        #expect(session.isSolving == false)
    }
    
    @Test("isCompletedWithoutMistakes: очередь пуста + нет failIDs + есть successIDs")
    func isCompletedWithoutMistakes() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(2))
        session.markCorrect()
        session.markCorrect()
        #expect(session.isCompletedWithoutMistakes == true)
        #expect(session.isCompletedWithMistakes == false)
    }
    
    @Test("isCompletedWithMistakes: очередь пуста + есть failIDs")
    func isCompletedWithMistakes() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(2))
        session.markCorrect()
        session.markWrong()
        #expect(session.isCompletedWithMistakes == true)
        #expect(session.isCompletedWithoutMistakes == false)
    }
    
    @Test("isUnfinished: что-то решено, но не всё")
    func isUnfinished() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(3))
        #expect(session.isUnfinished == false) // ничего не решено
        session.markCorrect()
        #expect(session.isUnfinished == true)
        session.markCorrect()
        session.markCorrect()
        #expect(session.isUnfinished == false)
    }
    
    @Test("Пустая сессия: ни solving, ни completed")
    func emptySessionState() {
        let session = SolveSession(groupKey: .system(.allCards), cardIDs: [])
        #expect(session.isSolving == false)
        #expect(session.isCompletedWithoutMistakes == false)
        #expect(session.isCompletedWithMistakes == false)
        #expect(session.isUnfinished == false)
    }
    
    // MARK: - markCorrect / markWrong
    
    @Test("markCorrect: карточка уходит из unsolved, попадает в success")
    func markCorrectMovesCard() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(2))
        let id = session.unsolvedIDs[0]
        session.markCorrect()
        #expect(!session.unsolvedIDs.contains(id))
        #expect(session.successIDs == [id])
        #expect(session.failIDs.isEmpty)
    }
    
    @Test("markWrong: карточка уходит из unsolved, попадает в fail")
    func markWrongMovesCard() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(2))
        let id = session.unsolvedIDs[0]
        session.markWrong()
        #expect(!session.unsolvedIDs.contains(id))
        #expect(session.successIDs.isEmpty)
        #expect(session.failIDs == [id])
    }
    
    @Test("markCorrect на пустой очереди — no-op")
    func markCorrectOnEmptyNoop() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: [])
        session.markCorrect()
        #expect(session.successIDs.isEmpty)
    }
    
    @Test("markWrong на пустой очереди — no-op")
    func markWrongOnEmptyNoop() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: [])
        session.markWrong()
        #expect(session.failIDs.isEmpty)
    }
    
    // MARK: - restartAll
    
    @Test("restartAll: сбрасывает всю сессию на новый перемешанный набор")
    func restartAllResets() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(3))
        session.markCorrect()
        session.markWrong()
        
        let all = ids(3)
        session.restartAll(from: all)
        
        #expect(session.successIDs.isEmpty)
        #expect(session.failIDs.isEmpty)
        #expect(session.unsolvedIDs.count == 3)
        #expect(Set(session.unsolvedIDs) == Set(all))
    }
    
    // MARK: - restartMistakes
    
    @Test("restartMistakes: оставляет только failIDs, обнуляет success")
    func restartMistakesKeepsOnlyFails() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(5))
        session.markCorrect()
        let fail1 = session.unsolvedIDs[0]
        session.markWrong()
        let fail2 = session.unsolvedIDs[0]
        session.markWrong()
        session.markCorrect()
        
        session.restartMistakes()
        
        #expect(Set(session.failIDs).isEmpty) // failIDs обнуляется
        #expect(session.successIDs.isEmpty)
        #expect(Set(session.unsolvedIDs) == Set([fail1, fail2]))
    }
    
    @Test("restartMistakes: если ошибок нет — unsolved пуст")
    func restartMistakesNoFails() {
        var session = SolveSession(groupKey: .system(.allCards), cardIDs: ids(2))
        session.markCorrect()
        session.markCorrect()
        session.restartMistakes()
        #expect(session.unsolvedIDs.isEmpty)
        #expect(session.isCompletedWithoutMistakes == false) // successIDs тоже пуст
    }
    
    // MARK: - Codable
    
    @Test("Codable: round-trip сохраняет состояние")
    func codableRoundTrip() throws {
        var session = SolveSession(groupKey: .user(UUID()), cardIDs: ids(3))
        session.markCorrect()
        session.markWrong()
        
        let data = try JSONEncoder().encode(session)
        let restored = try JSONDecoder().decode(SolveSession.self, from: data)
        
        #expect(restored == session)
    }
    
    @Test("Codable: пустая сессия сохраняется и восстанавливается")
    func codableEmpty() throws {
        let session = SolveSession(groupKey: .srs, cardIDs: [])
        let data = try JSONEncoder().encode(session)
        let restored = try JSONDecoder().decode(SolveSession.self, from: data)
        #expect(restored == session)
    }
    
    // MARK: - Equatable
    
    @Test("Equatable: две сессии с одинаковыми полями равны")
    func equatable() {
        let cardIDs = ids(2)
        var a = SolveSession(groupKey: .srs, cardIDs: cardIDs)
        var b = SolveSession(groupKey: .srs, cardIDs: cardIDs)
        a.unsolvedIDs = [cardIDs[0]]
        b.unsolvedIDs = [cardIDs[0]]
        #expect(a == b)
    }
    
    @Test("Equatable: разные successIDs → не равны")
    func notEqualDifferentSuccess() {
        let cardIDs = ids(2)
        var a = SolveSession(groupKey: .srs, cardIDs: cardIDs)
        var b = SolveSession(groupKey: .srs, cardIDs: cardIDs)
        a.successIDs = [cardIDs[0]]
        b.successIDs = [cardIDs[1]]
        #expect(a != b)
    }
}
