//
//  SolveSession.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Состояние нарешивания одной группы.
/// `unsolvedIDs` работает как очередь: первый элемент — текущая карточка.
struct SolveSession: Codable, Equatable {
    let groupKeyString: String
    var unsolvedIDs: [UUID]
    var successIDs: [UUID]
    var failIDs: [UUID]
    var studyDayKey: String? = nil
    var srsQualityCounts: [String: Int]? = nil
    
    var groupKey: SolveGroupKey? {
        SolveGroupKey(stringValue: groupKeyString)
    }
    
    // MARK: - Counts
    
    var totalCount: Int {
        unsolvedIDs.count + successIDs.count + failIDs.count
    }
    
    var solvedCount: Int {
        successIDs.count + failIDs.count
    }
    
    var currentCardID: UUID? {
        unsolvedIDs.first
    }
    
    // MARK: - State
    
    /// Есть что решать прямо сейчас.
    var isSolving: Bool {
        !unsolvedIDs.isEmpty
    }
    
    /// Раунд завершён, ошибок не было.
    var isCompletedWithoutMistakes: Bool {
        unsolvedIDs.isEmpty && failIDs.isEmpty && !successIDs.isEmpty
    }
    
    /// Раунд завершён, есть ошибки — можно повторить их.
    var isCompletedWithMistakes: Bool {
        unsolvedIDs.isEmpty && !failIDs.isEmpty
    }
    
    /// Сессия в процессе: что-то решено, но не всё.
    var isUnfinished: Bool {
        !unsolvedIDs.isEmpty && solvedCount > 0
    }
    
    // MARK: - Mutations
    
    mutating func markCorrect() {
        guard let id = unsolvedIDs.first else { return }
        unsolvedIDs.removeFirst()
        successIDs.append(id)
    }
    
    mutating func markWrong() {
        guard let id = unsolvedIDs.first else { return }
        unsolvedIDs.removeFirst()
        failIDs.append(id)
    }
    
    /// Сбросить всё и начать заново.
    mutating func restartAll(from allIDs: [UUID]) {
        unsolvedIDs = groupKey == .srs ? allIDs : allIDs.shuffled()
        successIDs = []
        failIDs = []
    }
    
    /// Начать заново только с ошибок.
    mutating func restartMistakes() {
        unsolvedIDs = failIDs.shuffled()
        successIDs = []
        failIDs = []
    }
    
    // MARK: - Init
    
    init(groupKey: SolveGroupKey, cardIDs: [UUID]) {
        self.groupKeyString = groupKey.stringValue
        self.unsolvedIDs = groupKey == .srs ? cardIDs : cardIDs.shuffled()
        self.successIDs = []
        self.failIDs = []
    }
}
