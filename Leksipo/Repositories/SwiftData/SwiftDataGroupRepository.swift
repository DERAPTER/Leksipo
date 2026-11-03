//
//  SwiftDataGroupRepository.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataGroupRepository: GroupRepository {
    private let context: ModelContext
    private let transaction: PersistenceTransaction
    
    init(context: ModelContext, transaction: PersistenceTransaction? = nil) {
        self.context = context
        self.transaction = transaction ?? PersistenceTransaction(context: context)
    }
    
    // MARK: - Fetch
    
    func fetchUserGroups() throws -> [CardGroup] {
        let predicate = #Predicate<CardGroup> { $0.systemTypeRaw == nil }
        let descriptor = FetchDescriptor<CardGroup>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.orderIndex, order: .forward)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func fetch(id: UUID) throws -> CardGroup? {
        let predicate = #Predicate<CardGroup> { $0.id == id }
        var descriptor = FetchDescriptor<CardGroup>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    func userGroupsCount() throws -> Int {
        let predicate = #Predicate<CardGroup> { $0.systemTypeRaw == nil }
        do {
            return try context.fetchCount(FetchDescriptor<CardGroup>(predicate: predicate))
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Mutations
    
    func create(name: String, languagePair: StudyLanguagePair? = nil) throws -> CardGroup {
        return try transaction.perform {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw RepositoryError.invalidInput(reason: "Название группы не может быть пустым")
            }

            if try nameExists(trimmed, excluding: nil) {
                throw RepositoryError.invalidInput(reason: "Группа с таким названием уже существует")
            }

            let nextIndex = try nextOrderIndex()
            let group = CardGroup(name: trimmed, orderIndex: nextIndex)
            let descriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { $0.id == "singleton" })
            group.languagePair = try languagePair ?? context.fetch(descriptor).first?.languagePair ?? .legacy
            context.insert(group)

            return group
        }
    }
    
    /// Исправление метаданных языка не меняет тексты и прогресс карточек.
    /// Общие карточки сначала нужно отвязать от других групп, чтобы не менять их неявно.
    func update(_ group: CardGroup, name: String, languagePair: StudyLanguagePair) throws {
        try transaction.perform {
            if languagePair != group.languagePair {
                guard group.cards.allSatisfy({ card in
                    card.groups.allSatisfy { $0.id == group.id || $0.languagePair == languagePair }
                }) else { throw StudyLanguageError.sharedCards }
                let allCards = try context.fetch(FetchDescriptor<Card>())
                let changingIDs = Set(group.cards.map(\.id))
                func textKey(_ card: Card) -> [String] {
                    [card.originWord, card.translatedWord].map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    }
                }
                let existingKeys = Set(allCards.filter {
                    !changingIDs.contains($0.id) && $0.languagePair == languagePair
                }.map(textKey))
                guard group.cards.allSatisfy({ !existingKeys.contains(textKey($0)) }) else {
                    throw StudyLanguageError.duplicateCard
                }
                transaction.track(group)
                for card in group.cards {
                    transaction.track(card)
                    card.languagePair = languagePair
                }
                group.languagePair = languagePair
            }
            try rename(group, to: name)
        }
    }

    func rename(_ group: CardGroup, to newName: String) throws {
        return try transaction.perform {
            transaction.track(group)
            for card in group.cards { transaction.track(card) }
            guard !group.isSystem else {
                throw RepositoryError.invalidInput(reason: "Системную группу нельзя переименовать")
            }

            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw RepositoryError.invalidInput(reason: "Название группы не может быть пустым")
            }

            if try nameExists(trimmed, excluding: group.id) {
                throw RepositoryError.invalidInput(reason: "Группа с таким названием уже существует")
            }

            group.name = trimmed

        }
    }
    
    func delete(_ group: CardGroup) throws {
        return try transaction.perform {
            transaction.track(group)
            for card in group.cards { transaction.track(card) }
            guard !group.isSystem else {
                throw RepositoryError.invalidInput(reason: "Системную группу нельзя удалить")
            }
            context.delete(group)

        }
    }
    
    func addCard(_ card: Card, to group: CardGroup) throws {
        return try transaction.perform {
            transaction.track(group)
            transaction.track(card)
            guard card.languagePair == group.languagePair else { throw StudyLanguageError.incompatibleGroup }
            guard !card.groups.contains(where: { $0.id == group.id }) else { return }
            card.groups.append(group)

        }
    }
    
    func removeCard(_ card: Card, from group: CardGroup) throws {
        return try transaction.perform {
            transaction.track(group)
            transaction.track(card)
            card.groups.removeAll { $0.id == group.id }

        }
    }
    
    // MARK: - Validation
    
    func nameExists(_ name: String, excluding groupID: UUID?) throws -> Bool {
        let lower = name.lowercased()
        do {
            let all = try context.fetch(FetchDescriptor<CardGroup>())
            return all.contains { group in
                if let excludeID = groupID, group.id == excludeID { return false }
                return group.name.lowercased() == lower
            }
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Private
    
    private func nextOrderIndex() throws -> Int {
        var descriptor = FetchDescriptor<CardGroup>(
            sortBy: [SortDescriptor(\.orderIndex, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        do {
            let last = try context.fetch(descriptor).first
            return (last?.orderIndex ?? -1) + 1
        } catch {
            throw RepositoryError.fetchFailed(underlying: error)
        }
    }
    

}
