//
//  SolveListViewModel.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
@Observable
final class SolveListViewModel {
    
    struct GroupItem: Identifiable, Hashable {
        let key: SolveGroupKey
        let name: String
        let totalCards: Int
        let solvedInSession: Int
        let hasUnfinishedSession: Bool
        
        var id: String { key.stringValue }
        
        static func == (lhs: GroupItem, rhs: GroupItem) -> Bool { lhs.key == rhs.key }
        func hash(into hasher: inout Hasher) { hasher.combine(key) }
    }
    
    private(set) var items: [GroupItem] = []
    private(set) var errorMessage: String?
    
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    private let sessionStore: SolveSessionStore
    
    init(
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        sessionStore: SolveSessionStore
    ) {
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.sessionStore = sessionStore
    }
    
    func load() {
        do {
            var result: [GroupItem] = []
            
            result.append(try makeItem(
                key: .system(.allCards),
                name: "all_cards".localized(),
                cards: cardRepository.fetchAll()
            ))
            
            result.append(try makeItem(
                key: .system(.favourites),
                name: "favourites".localized(),
                cards: cardRepository.fetchFavourites()
            ))
            
            for group in try groupRepository.fetchUserGroups() {
                result.append(try makeItem(
                    key: .user(group.id),
                    name: group.name,
                    cards: cardRepository.fetch(inGroup: group.id)
                ))
            }
            
            items = result
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func makeItem(
        key: SolveGroupKey,
        name: String,
        cards: [Card]
    ) throws -> GroupItem {
        let total = cards.count
        
        var solvedInSession = 0
        var hasUnfinished = false
        
        if let session = try sessionStore.load(for: key) {
            let currentIDs = Set(cards.map(\.id))
            let validSolved = (session.successIDs + session.failIDs)
                .filter { currentIDs.contains($0) }
            
            solvedInSession = validSolved.count
            hasUnfinished = !session.unsolvedIDs.isEmpty && solvedInSession > 0
        }
        
        return GroupItem(
            key: key,
            name: name,
            totalCards: total,
            solvedInSession: solvedInSession,
            hasUnfinishedSession: hasUnfinished
        )
    }
}
