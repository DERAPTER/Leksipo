//
//  SwiftDataCardRepository.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataCardRepository: CardRepository {
    private let context: ModelContext
    private let transaction: PersistenceTransaction
    private let calendar: Calendar
    private let defaults: UserDefaults
    private let now: () -> Date
    
    init(context: ModelContext, transaction: PersistenceTransaction? = nil, calendar: Calendar = StudyDay.calendar, defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }) {
        self.context = context
        self.calendar = calendar
        self.defaults = defaults
        self.now = now
        self.transaction = transaction ?? PersistenceTransaction(context: context)
    }
    
    // MARK: - Fetch
    
    func fetchAll() throws -> [Card] {
        let descriptor = FetchDescriptor<Card>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func fetch(id: UUID) throws -> Card? {
        let predicate = #Predicate<Card> { $0.id == id }
        var descriptor = FetchDescriptor<Card>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func fetch(inGroup groupID: UUID) throws -> [Card] {
        let predicate = #Predicate<Card> { card in
            card.groups.contains { $0.id == groupID }
        }
        let descriptor = FetchDescriptor<Card>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func fetchFavourites() throws -> [Card] {
        let predicate = #Predicate<Card> { $0.isFavourite == true }
        let descriptor = FetchDescriptor<Card>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func search(_ query: String) throws -> [Card] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try fetchAll() }
        
        let lower = trimmed.lowercased()
        let predicate = #Predicate<Card> { card in
            card.originWord.localizedStandardContains(lower) ||
            card.translatedWord.localizedStandardContains(lower)
        }
        let descriptor = FetchDescriptor<Card>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Counts
    
    func totalCount() throws -> Int {
        do {
            return try context.fetchCount(FetchDescriptor<Card>())
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func favouritesCount() throws -> Int {
        let predicate = #Predicate<Card> { $0.isFavourite == true }
        do {
            return try context.fetchCount(FetchDescriptor<Card>(predicate: predicate))
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func count(inGroup groupID: UUID) throws -> Int {
        let predicate = #Predicate<Card> { card in
            card.groups.contains { $0.id == groupID }
        }
        do {
            return try context.fetchCount(FetchDescriptor<Card>(predicate: predicate))
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Mutations
    
    func create(
        origin: String,
        translated: String,
        originDescription: String,
        translatedDescription: String,
        groups: [CardGroup],
        languagePair: StudyLanguagePair? = nil
    ) throws -> Card {
        return try transaction.perform {
            groups.forEach { transaction.track($0) }
            let trimmedOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTranslated = translated.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedOrigin.isEmpty, !trimmedTranslated.isEmpty else {
                throw RepositoryError.invalidInput(reason: "Слово и перевод не могут быть пустыми")
            }

            let trimmedOriginDesc = originDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTranslatedDesc = translatedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

            let card = Card(
                origin: trimmedOrigin,
                translated: trimmedTranslated,
                originDescription: trimmedOriginDesc,
                translatedDescription: trimmedTranslatedDesc,
                dateAdded: now()
            )
            let pair = try languagePair ?? groups.first?.languagePair ?? defaultLanguagePair()
            guard groups.allSatisfy({ $0.languagePair == pair }) else { throw StudyLanguageError.incompatibleGroup }
            card.languagePair = pair
            card.groups = groups
            context.insert(card)
            try noteNewSRSCard(on: card.dateAdded)

            return card
        }
    }
    
    func update(
        _ card: Card,
        origin: String,
        translated: String,
        originDescription: String,
        translatedDescription: String,
        groups: [CardGroup],
        languagePair: StudyLanguagePair? = nil
    ) throws {
        return try transaction.perform {
            (card.groups + groups).forEach { transaction.track($0) }
            transaction.track(card)
            let trimmedOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTranslated = translated.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedOrigin.isEmpty, !trimmedTranslated.isEmpty else {
                throw RepositoryError.invalidInput(reason: "Слово и перевод не могут быть пустыми")
            }

            let pair = languagePair ?? card.languagePair
            guard groups.allSatisfy({ $0.languagePair == pair }) else { throw StudyLanguageError.incompatibleGroup }
            card.languagePair = pair
            card.originWord = trimmedOrigin
            card.translatedWord = trimmedTranslated
            card.originDescription = originDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            card.translatedDescription = translatedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            card.groups = groups

        }
    }
    
    func toggleFavourite(_ card: Card) throws {
        return try transaction.perform {
            transaction.track(card)
            card.isFavourite.toggle()

        }
    }
    
    func delete(_ card: Card) throws {
        return try transaction.perform {
            card.groups.forEach { transaction.track($0) }
            transaction.track(card)
            context.delete(card)

        }
    }
    
    func recordAnswer(_ card: Card, correct: Bool) throws {
        return try transaction.perform {
            transaction.track(card)
            if correct {
                card.correctCount += 1
            } else {
                card.wrongCount += 1
            }

        }
    }
    
    // MARK: - Validation
    
    func exists(origin: String, translated: String, excluding cardID: UUID?, languagePair: StudyLanguagePair? = nil) throws -> Bool {
        let pair = try languagePair ?? defaultLanguagePair()
        let lowerOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lowerTranslated = translated.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        do {
            let all = try context.fetch(FetchDescriptor<Card>())
            return all.contains { card in
                if let excludeID = cardID, card.id == excludeID { return false }
                return card.languagePair == pair && card.originWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowerOrigin &&
                       card.translatedWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowerTranslated
            }
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - SRS (SM-2)
    
    func fetchDueToday(on date: Date, newCardsLimit: Int) throws -> [Card] {
        let end = StudyDay.end(of: date, calendar: calendar)
        let all = try fetchAll()
        let remaining = max(0, max(0, newCardsLimit) - (try dailyStat(on: date)?.srsNewCardsIntroduced ?? 0))
        let due = all.filter { !$0.isNewInSRS && ($0.nextReviewDate.map { $0 < end } ?? false) }
            .sorted {
                if $0.nextReviewDate != $1.nextReviewDate { return ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
                return $0.id.uuidString < $1.id.uuidString
            }
        let newCards = all.filter(\.isNewInSRS).sorted {
            if $0.dateAdded != $1.dateAdded { return $0.dateAdded < $1.dateAdded }
            return $0.id.uuidString < $1.id.uuidString
        }
        return due + newCards.prefix(remaining)
    }

    func dueTodayCount(on date: Date, newCardsLimit: Int) throws -> Int {
        try fetchDueToday(on: date, newCardsLimit: newCardsLimit).count
    }
    
    func recordSRSReview(_ card: Card, quality: Int, on date: Date) throws {
        return try transaction.perform {
            transaction.track(card)
            let stat: DailyStat
            if let existing = try dailyStat(on: date) {
                stat = existing
                transaction.track(stat)
            } else {
                stat = DailyStat(date: date)
                stat.dateKey = StudyDay.key(for: date, calendar: calendar)
                stat.date = calendar.startOfDay(for: date)
                context.insert(stat)
            }
            if card.isNewInSRS { stat.srsNewCardsIntroduced += 1 }
            stat.srsReviewCount += 1
            let prediction = SRSAlgorithm.predict(
                quality: quality,
                currentEaseFactor: card.easeFactor,
                currentIntervalDays: card.intervalDays,
                currentRepetitions: card.repetitions,
                from: date,
                calendar: calendar
            )

            card.intervalDays = prediction.intervalDays
            card.repetitions = prediction.repetitions
            card.easeFactor = prediction.easeFactor
            card.nextReviewDate = prediction.nextReviewDate
            card.lastReviewDate = date

            if quality >= 3 {
                card.correctCount += 1
            } else {
                card.wrongCount += 1
            }


        }
    }
    
    func srsOverview(on date: Date, newCardsLimit: Int) throws -> SRSOverview {
        let end = StudyDay.end(of: date, calendar: calendar)
        let all = try fetchAll()
        let queue = try fetchDueToday(on: date, newCardsLimit: newCardsLimit)
        var futureByDay: [Date: Int] = [:]
        for card in all where !card.isNewInSRS {
            if let next = card.nextReviewDate, next >= end {
                futureByDay[calendar.startOfDay(for: next), default: 0] += 1
            }
        }
        let newAvailable = queue.filter(\.isNewInSRS).count
        let remainingNew = all.filter(\.isNewInSRS).count - newAvailable
        if remainingNew > 0 && newCardsLimit > 0 {
            // После исчерпания сегодняшнего лимита новые слова доступны завтра.
            futureByDay[end, default: 0] += min(remainingNew, newCardsLimit)
        }
        let nextDate = futureByDay.keys.min()
        return SRSOverview(
            dueToday: queue.count, overdueCount: queue.count - newAvailable,
            newCardsAvailable: newAvailable, nextReviewDate: nextDate,
            nextReviewCount: nextDate.flatMap { futureByDay[$0] } ?? 0
        )
    }

    private func noteNewSRSCard(on date: Date) throws {
        let limit = defaults.integer(forKey: "srsNewCardsPerDay")
        let effectiveLimit = limit > 0 ? limit : 20
        let today = try dailyStat(on: date)
        let hasRoomToday = (today?.srsNewCardsIntroduced ?? 0) < effectiveLimit
        let day = hasRoomToday ? calendar.startOfDay(for: date) : StudyDay.end(of: date, calendar: calendar)
        let key = StudyDay.key(for: day, calendar: calendar)
        if hasRoomToday, let today, today.srsCleared {
            transaction.track(today)
            today.srsCleared = false
        }
        let latest = try context.fetch(FetchDescriptor<DailyStat>())
            .filter { $0.srsCleared && $0.dateKey <= key }.max { $0.dateKey < $1.dateKey }
        if let latest, latest.srsNextDueDayKey.map({ $0 > key }) ?? false {
            transaction.track(latest)
            latest.srsNextDueDayKey = key
        }
    }

    private func defaultLanguagePair() throws -> StudyLanguagePair {
        let descriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { $0.id == "singleton" })
        return try context.fetch(descriptor).first?.languagePair ?? .legacy
    }

    private func dailyStat(on date: Date) throws -> DailyStat? {
        let key = StudyDay.key(for: date, calendar: calendar)
        return try context.fetch(FetchDescriptor<DailyStat>(predicate: #Predicate { $0.dateKey == key })).first
    }
}
