//
//  GroupsListViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class GroupsListViewModel {
    
    // MARK: - State
    
    private(set) var userGroups: [CardGroup] = []
    private(set) var allCardsCount: Int = 0
    private(set) var favouritesCount: Int = 0
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    /// Какие группы сейчас развёрнуты (по GroupDisplayItem.id)
    private(set) var expandedGroupIDs: Set<String> = []
    
    /// Кеш загруженных карточек по GroupDisplayItem.id
    private(set) var cardsCache: [String: [Card]] = [:]
    
    // MARK: - Dependencies
    
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    private let achievementsService: AchievementsService
    
    init(
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        achievementsService: AchievementsService
    ) {
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.achievementsService = achievementsService
    }
    
    // MARK: - Derived
    
    var displayItems: [GroupDisplayItem] {
        var items: [GroupDisplayItem] = [
            .system(.allCards),
            .system(.favourites)
        ]
        items.append(contentsOf: userGroups.map(GroupDisplayItem.user))
        return items
    }
    
    func cardCount(for item: GroupDisplayItem) -> Int {
        switch item {
        case .system(.allCards):   return allCardsCount
        case .system(.favourites): return favouritesCount
        case .user(let group):     return group.cards.count
        }
    }
    
    func isExpanded(_ item: GroupDisplayItem) -> Bool {
        expandedGroupIDs.contains(item.id)
    }
    
    func cards(for item: GroupDisplayItem) -> [Card] {
        cardsCache[item.id] ?? []
    }
    
    // MARK: - Loading
    
    func load() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            userGroups = try groupRepository.fetchUserGroups()
            allCardsCount = try cardRepository.totalCount()
            favouritesCount = try cardRepository.favouritesCount()
            
            // Перезагружаем кеш для всех открытых групп
            reloadExpandedCaches()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Expansion
    
    func toggleExpansion(_ item: GroupDisplayItem) {
        if expandedGroupIDs.contains(item.id) {
            expandedGroupIDs.remove(item.id)
            cardsCache.removeValue(forKey: item.id)
        } else {
            expandedGroupIDs.insert(item.id)
            loadCards(for: item)
        }
    }
    
    func collapse(_ item: GroupDisplayItem) {
        expandedGroupIDs.remove(item.id)
        cardsCache.removeValue(forKey: item.id)
    }
    
    private func loadCards(for item: GroupDisplayItem) {
        do {
            let cards: [Card]
            switch item {
            case .system(.allCards):
                cards = try cardRepository.fetchAll()
            case .system(.favourites):
                cards = try cardRepository.fetchFavourites()
            case .user(let group):
                cards = try cardRepository.fetch(inGroup: group.id)
            }
            cardsCache[item.id] = cards
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func reloadExpandedCaches() {
        for id in expandedGroupIDs {
            guard let item = displayItems.first(where: { $0.id == id }) else { continue }
            loadCards(for: item)
        }
    }
    
    // MARK: - Group mutations
    
    @discardableResult
    func createGroup(name: String, languagePair: StudyLanguagePair? = nil) throws -> CardGroup {
        let group = try groupRepository.create(name: name, languagePair: languagePair)
        _ = achievementsService.evaluate()
        load()
        return group
    }
    
    func deleteGroup(_ group: CardGroup) throws {
        try groupRepository.delete(group)
        load()
    }
    
    // MARK: - Card mutations
    
    func toggleFavourite(_ card: Card) throws {
        try cardRepository.toggleFavourite(card)
        _ = achievementsService.evaluate()
        refreshAfterCardMutation()
    }
    
    func deleteCardFromGroup(_ card: Card, group: CardGroup) throws {
        try groupRepository.removeCard(card, from: group)
        refreshAfterCardMutation()
    }
    
    func deleteCardCompletely(_ card: Card) throws {
        try cardRepository.delete(card)
        refreshAfterCardMutation()
    }
    
    /// Вызывается после добавления карточки через sheet.
    func handleCardAdded() {
        load()
    }
    
    private func refreshAfterCardMutation() {
        // Пересчитываем счётчики + перезагружаем открытые группы
        do {
            allCardsCount = try cardRepository.totalCount()
            favouritesCount = try cardRepository.favouritesCount()
            reloadExpandedCaches()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
