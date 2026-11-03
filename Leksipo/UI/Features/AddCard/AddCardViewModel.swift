//
//  AddCardViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AddCardViewModel {
    
    enum Mode: String, CaseIterable {
        case createNew
        case chooseExisting
        
        var titleKey: String {
            switch self {
            case .createNew:      return "create_new"
            case .chooseExisting: return "choose_existing"
            }
        }
    }
    
    // MARK: - State: Mode
    
    var mode: Mode = .createNew
    
    // MARK: - State: Create New
    
    var originWord = ""
    var translatedWord = ""
    var originDescription = ""
    var translatedDescription = ""
    private(set) var selectedGroups: [CardGroup] = []
    private(set) var availableGroups: [CardGroup] = []
    
    // MARK: - State: Choose Existing
    
    var searchText = ""
    private(set) var allExistingCards: [Card] = []
    private(set) var selectedCardIDs: Set<UUID> = []
    
    // MARK: - State: Alerts
    
    var showDuplicateAlert = false
    var showLanguageCopyConfirmation = false
    private var cardToCopy: Card?
    var languagePair: StudyLanguagePair { targetGroup.languagePair }

    func prepareLanguageCopy() {
        guard let card = cardToCopy else { return }
        originWord = card.originWord
        translatedWord = card.translatedWord
        originDescription = card.originDescription
        translatedDescription = card.translatedDescription
        mode = .createNew
        cardToCopy = nil
    }
    var showSuccessAlert = false
    var addedCardsCount = 0
    private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let targetGroup: CardGroup
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    private let achievementsService: AchievementsService
    
    init(
        targetGroup: CardGroup,
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        achievementsService: AchievementsService
    ) {
        self.targetGroup = targetGroup
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.achievementsService = achievementsService
    }
    
    // MARK: - Derived
    
    var canSaveNewCard: Bool {
        !originWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translatedWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canAddSelected: Bool {
        !selectedCardIDs.isEmpty
    }
    
    var filteredExistingCards: [Card] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allExistingCards }
        return allExistingCards.filter { card in
            card.originWord.localizedCaseInsensitiveContains(trimmed) ||
            card.translatedWord.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    var targetGroupName: String {
        targetGroup.name
    }
    
    func isCardInTargetGroup(_ card: Card) -> Bool {
        card.groups.contains { $0.id == targetGroup.id }
    }
    
    // MARK: - Loading
    
    func onAppear() {
        loadGroups()
        loadExistingCards()
    }
    
    private func loadGroups() {
        do {
            let userGroups = try groupRepository.fetchUserGroups().filter { $0.languagePair == languagePair }
            
            // targetGroup всегда выбран и не может быть снят
            if !selectedGroups.contains(where: { $0.id == targetGroup.id }) {
                selectedGroups = [targetGroup]
            }
            
            availableGroups = userGroups.filter { group in
                !selectedGroups.contains(where: { $0.id == group.id })
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadExistingCards() {
        do {
            allExistingCards = try cardRepository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Group selection (createNew)
    
    func toggleGroup(_ group: CardGroup) {
        // targetGroup нельзя снять
        guard group.id != targetGroup.id, group.languagePair == languagePair else { return }
        
        if selectedGroups.contains(where: { $0.id == group.id }) {
            selectedGroups.removeAll { $0.id == group.id }
            availableGroups.append(group)
        } else {
            availableGroups.removeAll { $0.id == group.id }
            selectedGroups.append(group)
        }
    }
    
    // MARK: - Card selection (chooseExisting)
    
    func toggleCardSelection(_ card: Card) {
        guard !isCardInTargetGroup(card) else { return }
        guard card.languagePair == languagePair else {
            cardToCopy = card
            showLanguageCopyConfirmation = true
            return
        }
        
        if selectedCardIDs.contains(card.id) {
            selectedCardIDs.remove(card.id)
        } else {
            selectedCardIDs.insert(card.id)
        }
    }
    
    func clearSelection() {
        selectedCardIDs.removeAll()
    }
    
    // MARK: - Actions
    
    /// Создаёт новую карточку и добавляет её в выбранные группы.
    /// Возвращает true при успехе — View закроет sheet.
    func saveNewCard() -> Bool {
        let trimmedOrigin = originWord.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslated = translatedWord.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedOrigin.isEmpty, !trimmedTranslated.isEmpty else { return false }
        
        do {
            let exists = try cardRepository.exists(
                origin: trimmedOrigin,
                translated: trimmedTranslated,
                excluding: nil, languagePair: languagePair
            )
            if exists {
                showDuplicateAlert = true
                return false
            }
            
            _ = try cardRepository.create(
                origin: trimmedOrigin,
                translated: trimmedTranslated,
                originDescription: originDescription,
                translatedDescription: translatedDescription,
                groups: selectedGroups, languagePair: languagePair
            )
            
            _ = achievementsService.evaluate()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Добавляет выбранные существующие карточки в targetGroup.
    func addSelectedCardsToGroup() {
        let cardsToAdd = allExistingCards.filter { selectedCardIDs.contains($0.id) }
        guard !cardsToAdd.isEmpty else { return }
        
        do {
            for card in cardsToAdd {
                try groupRepository.addCard(card, to: targetGroup)
            }
            addedCardsCount = cardsToAdd.count
            selectedCardIDs.removeAll()
            showSuccessAlert = true
            // Обновим список, чтобы пометить добавленные как "already in group"
            loadExistingCards()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
