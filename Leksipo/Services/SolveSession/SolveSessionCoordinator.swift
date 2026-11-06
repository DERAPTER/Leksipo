//
//  SolveSessionCoordinator.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Сохраняет прогресс свободных тренировок. SRS-очередь пересобирается
/// по назначениям текущего учебного дня; принятые ответы остаются в истории сессии.
@MainActor
final class SolveSessionCoordinator {
    private let store: SolveSessionStore
    private let cardRepository: CardRepository
    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar

    var newCardsLimit: Int {
        let limit = defaults.integer(forKey: "srsNewCardsPerDay")
        return limit > 0 ? limit : 20
    }

    var currentDate: Date { now() }
    
    init(store: SolveSessionStore, cardRepository: CardRepository, defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }, calendar: Calendar = StudyDay.calendar) {
        self.store = store
        self.cardRepository = cardRepository
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
    }
    
    /// Возвращает актуальную сессию для группы.
    func currentSession(for key: SolveGroupKey) throws -> SolveSession {
        if case .srs = key {
            let date = now()
            let dayKey = StudyDay.key(for: date, calendar: calendar)
            let dueIDs = try cardRepository.fetchDueToday(on: date, newCardsLimit: newCardsLimit).map(\.id)
            var session = try store.load(for: key) ?? SolveSession(groupKey: key, cardIDs: [])
            if session.studyDayKey != dayKey {
                // Старый JSON без даты тоже обновляется по актуальному расписанию.
                session = SolveSession(groupKey: key, cardIDs: [])
                session.studyDayKey = dayKey
            }
            // Репозиторий определяет порядок и оставшийся дневной лимит.
            // UUID отвеченных карточек сохраняем даже после их удаления.
            session.unsolvedIDs = reconciledSRSQueue(session.unsolvedIDs, dueIDs: dueIDs)
            if session.unsolvedIDs.isEmpty { try store.clear(for: key) }
            else { try store.save(session, for: key) }
            return session
        }

        // Остальные режимы — как раньше
        let currentCardIDs = try fetchCardIDs(for: key)
        
        guard var session = try store.load(for: key) else {
            let fresh = SolveSession(groupKey: key, cardIDs: currentCardIDs)
            try store.save(fresh, for: key)
            return fresh
        }
        
        session = reconcile(session: session, with: currentCardIDs)
        try store.save(session, for: key)
        return session
    }
    
    /// Начать заново — полностью.
    func restartAll(for key: SolveGroupKey) throws -> SolveSession {
        if key == .srs { return try currentSession(for: key) }
        let cardIDs = try fetchCardIDs(for: key)
        var session = SolveSession(groupKey: key, cardIDs: cardIDs)
        session.restartAll(from: cardIDs)
        try store.save(session, for: key)
        return session
    }
    
    /// Начать заново с ошибок.
    func restartMistakes(_ session: SolveSession) throws -> SolveSession {
        var updated = session
        updated.restartMistakes()
        if let key = session.groupKey {
            try store.save(updated, for: key)
        }
        return updated
    }
    
    func markCorrect(_ session: SolveSession, quality: SRSQuality? = nil) throws -> SolveSession {
        var updated = session
        if quality?.requiresRelearning == true {
            // Не считаем карточку завершённой до оценки >= 4.
            if !updated.unsolvedIDs.isEmpty { updated.unsolvedIDs.removeFirst() }
        } else {
            updated.markCorrect()
        }
        if let quality {
            var counts = updated.srsQualityCounts ?? [:]
            counts[String(quality.rawValue), default: 0] += 1
            updated.srsQualityCounts = counts
        }
        try persistIfNeeded(updated)
        return updated
    }
    
    func refreshSRSQueue(_ session: SolveSession, on date: Date) throws -> SolveSession {
        var updated = session
        let dueIDs = try cardRepository.fetchDueToday(on: date, newCardsLimit: newCardsLimit).map(\.id)
        updated.unsolvedIDs = reconciledSRSQueue(session.unsolvedIDs, dueIDs: dueIDs)
        if updated.unsolvedIDs.isEmpty { try store.clear(for: .srs) }
        else { try store.save(updated, for: .srs) }
        return updated
    }

    func markWrong(_ session: SolveSession) throws -> SolveSession {
        var updated = session
        updated.markWrong()
        try persistIfNeeded(updated)
        return updated
    }
    
    func clear(for key: SolveGroupKey) throws {
        try store.clear(for: key)
    }
    
    func validateCurrent(_ session: SolveSession, on date: Date? = nil) throws {
        if session.groupKey == .srs,
           session.studyDayKey != StudyDay.key(for: date ?? now(), calendar: calendar) {
            throw PersistenceError.staleSession
        }
        guard let key = session.groupKey,
              let saved = try store.load(for: key), saved == session else {
            throw PersistenceError.staleSession
        }
    }

    // MARK: - Private
    
    private func reconciledSRSQueue(_ currentIDs: [UUID], dueIDs: [UUID]) -> [UUID] {
        let due = Set(dueIDs)
        let retained = currentIDs.filter { due.contains($0) }
        let known = Set(retained)
        // Только что отвеченная карточка попадёт в конец, а порядок после выхода сохранится.
        return retained + dueIDs.filter { !known.contains($0) }
    }

    private func reconcile(session: SolveSession, with currentIDs: [UUID]) -> SolveSession {
        let currentSet = Set(currentIDs)
        var updated = session
        
        updated.unsolvedIDs = session.unsolvedIDs.filter { currentSet.contains($0) }
        updated.successIDs  = session.successIDs.filter  { currentSet.contains($0) }
        updated.failIDs     = session.failIDs.filter     { currentSet.contains($0) }
        
        let knownIDs = Set(updated.unsolvedIDs + updated.successIDs + updated.failIDs)
        let newIDs = currentIDs.filter { !knownIDs.contains($0) }
        updated.unsolvedIDs.append(contentsOf: newIDs.shuffled())
        
        return updated
    }
    
    private func persistIfNeeded(_ session: SolveSession) throws {
        guard let key = session.groupKey else { return }
        
        // Для SRS-сессии: как только все карточки отвечены — чистим.
        // Для остальных: чистим, когда всё правильно, без ошибок.
        if session.isCompletedWithoutMistakes {
            try store.clear(for: key)
        } else {
            try store.save(session, for: key)
        }
    }
    
    private func fetchCardIDs(for key: SolveGroupKey) throws -> [UUID] {
        switch key {
        case .system(.allCards):
            return try cardRepository.fetchAll().map(\.id)
        case .system(.favourites):
            return try cardRepository.fetchFavourites().map(\.id)
        case .user(let id):
            return try cardRepository.fetch(inGroup: id).map(\.id)
        case .practice(let ids):
            let existing = Set(try cardRepository.fetchAll().map(\.id))
            return ids.filter { existing.contains($0) }
        case .srs:
            return try cardRepository.fetchDueToday(on: now(), newCardsLimit: newCardsLimit).map(\.id)
        }
    }
}
