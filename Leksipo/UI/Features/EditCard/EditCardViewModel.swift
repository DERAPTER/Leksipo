//
//  EditCardViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
@Observable
final class EditCardViewModel {
    
    // MARK: - Identity
    
    let card: Card
    
    // MARK: - Original state (для отслеживания изменений)
    
    private let originalOrigin: String
    private let originalTranslated: String
    private let originalOriginDescription: String
    private let originalTranslatedDescription: String
    private let originalGroupIDs: Set<UUID>
    
    // MARK: - Editable state
    
    var editedLanguagePair: StudyLanguagePair
    private let originalLanguagePair: StudyLanguagePair
    var editedOrigin: String
    var editedTranslated: String
    var editedOriginDescription: String
    var editedTranslatedDescription: String
    
    private(set) var selectedGroups: [CardGroup] = []
    private(set) var availableGroups: [CardGroup] = []
    private(set) var hasLoadedGroups = false
    
    // MARK: - Alerts
    
    var showDeleteConfirmation = false
    var showDuplicateAlert = false
    private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    
    init(
        card: Card,
        cardRepository: CardRepository,
        groupRepository: GroupRepository
    ) {
        self.card = card
        self.editedLanguagePair = card.languagePair
        self.originalLanguagePair = card.languagePair
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        
        self.originalOrigin = card.originWord
        self.originalTranslated = card.translatedWord
        self.originalOriginDescription = card.originDescription
        self.originalTranslatedDescription = card.translatedDescription
        self.originalGroupIDs = Set(card.groups.map(\.id))
        
        self.editedOrigin = card.originWord
        self.editedTranslated = card.translatedWord
        self.editedOriginDescription = card.originDescription
        self.editedTranslatedDescription = card.translatedDescription
        self.selectedGroups = card.groups
    }
    
    // MARK: - Derived
    
    var canSave: Bool {
        hasLoadedGroups &&
        !editedOrigin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedTranslated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasChanges: Bool {
        let trimmedOrigin = editedOrigin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslated = editedTranslated.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOriginDesc = editedOriginDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslatedDesc = editedTranslatedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentGroupIDs = Set(selectedGroups.map(\.id))
        
        return editedLanguagePair != originalLanguagePair || trimmedOrigin != originalOrigin ||
               trimmedTranslated != originalTranslated ||
               trimmedOriginDesc != originalOriginDescription ||
               trimmedTranslatedDesc != originalTranslatedDescription ||
               currentGroupIDs != originalGroupIDs
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        loadGroups()
    }
    
    private func loadGroups() {
        // Повторное появление экрана не должно сбрасывать выбор групп в черновике.
        guard !hasLoadedGroups else { return }

        do {
            let userGroups = try groupRepository.fetchUserGroups()
            let cardGroupIDs = Set(card.groups.map(\.id))
            
            selectedGroups = userGroups.filter { cardGroupIDs.contains($0.id) }
            availableGroups = userGroups.filter { !cardGroupIDs.contains($0.id) && $0.languagePair == editedLanguagePair }
            hasLoadedGroups = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refreshAvailableGroups() {
        do {
            availableGroups = try groupRepository.fetchUserGroups().filter { group in
                group.languagePair == editedLanguagePair && !selectedGroups.contains { $0.id == group.id }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Group toggle
    
    func toggleGroup(_ group: CardGroup) {
        guard hasLoadedGroups else { return }
        guard selectedGroups.contains(where: { $0.id == group.id }) || group.languagePair == editedLanguagePair else { return }

        if selectedGroups.contains(where: { $0.id == group.id }) {
            selectedGroups.removeAll { $0.id == group.id }
            if group.languagePair == editedLanguagePair { availableGroups.append(group) }
        } else {
            availableGroups.removeAll { $0.id == group.id }
            selectedGroups.append(group)
        }
    }
    
    // MARK: - Actions
    
    /// Возвращает true при успешном сохранении.
    func save() -> Bool {
        // Пустой список после ошибки чтения нельзя принимать за выбор пользователя.
        guard canSave else { return false }

        let trimmedOrigin = editedOrigin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslated = editedTranslated.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let wordsChanged = editedLanguagePair != originalLanguagePair || trimmedOrigin != originalOrigin || trimmedTranslated != originalTranslated
            if wordsChanged {
                let exists = try cardRepository.exists(
                    origin: trimmedOrigin,
                    translated: trimmedTranslated,
                    excluding: card.id, languagePair: editedLanguagePair
                )
                if exists {
                    showDuplicateAlert = true
                    return false
                }
            }
            
            try cardRepository.update(
                card,
                origin: trimmedOrigin,
                translated: trimmedTranslated,
                originDescription: editedOriginDescription,
                translatedDescription: editedTranslatedDescription,
                groups: selectedGroups, languagePair: editedLanguagePair
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Возвращает true при успешном удалении.
    func delete() -> Bool {
        do {
            try cardRepository.delete(card)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
