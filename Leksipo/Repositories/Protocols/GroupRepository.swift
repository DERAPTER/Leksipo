//
//  GroupRepository.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
protocol GroupRepository {
    // Fetch
    func fetchUserGroups() throws -> [CardGroup]
    func fetch(id: UUID) throws -> CardGroup?
    
    // Counts
    func userGroupsCount() throws -> Int
    
    // Mutations
    func create(name: String, languagePair: StudyLanguagePair?) throws -> CardGroup
    func update(_ group: CardGroup, name: String, languagePair: StudyLanguagePair) throws
    func rename(_ group: CardGroup, to newName: String) throws
    func delete(_ group: CardGroup) throws
    func addCard(_ card: Card, to group: CardGroup) throws
    func removeCard(_ card: Card, from group: CardGroup) throws
    
    // Validation
    func nameExists(_ name: String, excluding groupID: UUID?) throws -> Bool
}


extension GroupRepository {
    func create(name: String) throws -> CardGroup { try create(name: name, languagePair: nil) }
}
