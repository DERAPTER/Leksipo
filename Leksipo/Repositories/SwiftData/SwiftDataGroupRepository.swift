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
    
    func create(name: String) throws -> CardGroup {
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
            context.insert(group)

            return group
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
