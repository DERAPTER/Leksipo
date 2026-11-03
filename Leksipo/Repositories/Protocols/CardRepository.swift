//
//  CardRepository.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
protocol CardRepository {
    // MARK: - Fetch
    func fetchAll() throws -> [Card]
    func fetch(id: UUID) throws -> Card?
    func fetch(inGroup groupID: UUID) throws -> [Card]
    func fetchFavourites() throws -> [Card]
    func search(_ query: String) throws -> [Card]
    
    // MARK: - Counts
    func totalCount() throws -> Int
    func favouritesCount() throws -> Int
    func count(inGroup groupID: UUID) throws -> Int
    
    // MARK: - Mutations
    func create(
        origin: String,
        translated: String,
        originDescription: String,
        translatedDescription: String,
        groups: [CardGroup],
        languagePair: StudyLanguagePair?
    ) throws -> Card
    
    func update(
        _ card: Card,
        origin: String,
        translated: String,
        originDescription: String,
        translatedDescription: String,
        groups: [CardGroup],
        languagePair: StudyLanguagePair?
    ) throws
    
    func toggleFavourite(_ card: Card) throws
    func delete(_ card: Card) throws
    func recordAnswer(_ card: Card, correct: Bool) throws
    
    // MARK: - Validation
    func exists(origin: String, translated: String, excluding cardID: UUID?, languagePair: StudyLanguagePair?) throws -> Bool
    
    // MARK: - SRS (SM-2)
    /// Карточки к повторению на указанную дату:
    /// просроченные + не более `newCardsLimit` новых.
    func fetchDueToday(on date: Date, newCardsLimit: Int) throws -> [Card]
    
    /// Количество карточек к повторению на дату.
    func dueTodayCount(on date: Date, newCardsLimit: Int) throws -> Int
    
    /// Обновляет SRS-состояние карточки по оценке (0...5).
    /// Также инкрементирует correctCount (q ≥ 3) или wrongCount (q < 3).
    func recordSRSReview(_ card: Card, quality: Int, on date: Date) throws
    
    /// Снимок SRS-состояния для экрана обзора.
    /// Показывает, что доступно сегодня, и когда будет следующее повторение.
    func srsOverview(on date: Date, newCardsLimit: Int) throws -> SRSOverview
}

// MARK: - Convenience overloads (обратная совместимость)

extension CardRepository {
    func create(origin: String, translated: String, originDescription: String, translatedDescription: String,
                groups: [CardGroup]) throws -> Card {
        try create(origin: origin, translated: translated, originDescription: originDescription,
                   translatedDescription: translatedDescription, groups: groups, languagePair: nil)
    }

    func update(_ card: Card, origin: String, translated: String, originDescription: String,
                translatedDescription: String, groups: [CardGroup]) throws {
        try update(card, origin: origin, translated: translated, originDescription: originDescription,
                   translatedDescription: translatedDescription, groups: groups, languagePair: nil)
    }

    func exists(origin: String, translated: String, excluding cardID: UUID?) throws -> Bool {
        try exists(origin: origin, translated: translated, excluding: cardID, languagePair: nil)
    }

    
    /// Создать карточку без описаний.
    @discardableResult
    func create(
        origin: String,
        translated: String,
        groups: [CardGroup],
        languagePair: StudyLanguagePair? = nil
    ) throws -> Card {
        try create(
            origin: origin,
            translated: translated,
            originDescription: "",
            translatedDescription: "",
            groups: groups, languagePair: languagePair
        )
    }
    
    /// Обновить карточку без изменения описаний.
    func update(
        _ card: Card,
        origin: String,
        translated: String,
        groups: [CardGroup],
        languagePair: StudyLanguagePair? = nil
    ) throws {
        try update(
            card,
            origin: origin,
            translated: translated,
            originDescription: card.originDescription,
            translatedDescription: card.translatedDescription,
            groups: groups, languagePair: languagePair
        )
    }
}
