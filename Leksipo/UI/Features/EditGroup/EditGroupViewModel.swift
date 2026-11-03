//
//  EditGroupViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
@Observable
final class EditGroupViewModel {
    
    // MARK: - Identity
    
    let group: CardGroup
    
    // MARK: - Editable state
    
    var editedName: String
    
    // MARK: - Alerts
    
    var showDeleteConfirmation = false
    var showErrorAlert = false
    private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let groupRepository: GroupRepository
    
    init(group: CardGroup, groupRepository: GroupRepository) {
        self.group = group
        self.groupRepository = groupRepository
        self.editedName = group.name
    }
    
    // MARK: - Derived
    
    var canSave: Bool {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != group.name
    }
    
    // MARK: - Actions
    
    /// Возвращает true при успешном сохранении.
    func save() -> Bool {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        do {
            try groupRepository.rename(group, to: trimmed)
            return true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            return false
        }
    }
    
    /// Возвращает true при успешном удалении.
    func delete() -> Bool {
        do {
            try groupRepository.delete(group)
            return true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            return false
        }
    }
    
    func resetEditedName() {
        editedName = group.name
    }
}
