//
//  GroupRowView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct GroupRowView: View {
    let item: GroupDisplayItem
    @Bindable var viewModel: GroupsListViewModel
    
    let onEdit: (CardGroup) -> Void
    let onDelete: (CardGroup) -> Void
    let onEditCard: (Card) -> Void
    let onAddCard: (CardGroup) -> Void
    
    @State private var swipeState: SwipeableItem = .none
    @State private var cardToDeleteFromGroup: Card?
    @State private var showDeleteCardDialog = false
    
    private var isExpanded: Bool {
        viewModel.isExpanded(item)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SwipeableGroupHeader(
                item: item,
                cardCount: viewModel.cardCount(for: item),
                isExpanded: isExpanded,
                onTap: { viewModel.toggleExpansion(item) },
                onEdit: handleEdit,
                onDelete: handleDelete,
                swipeState: $swipeState
            )
            
            if isExpanded {
                expandedContent
            }
        }
        .confirmationDialog(
            "delete_card".localized(),
            isPresented: $showDeleteCardDialog,
            titleVisibility: .visible
        ) {
            if let card = cardToDeleteFromGroup, let group = item.userGroup {
                Button(
                    String(format: "delete_from_group".localized(), group.name),
                    role: .destructive
                ) {
                    try? viewModel.deleteCardFromGroup(card, group: group)
                    cardToDeleteFromGroup = nil
                }
            }
            
            if let card = cardToDeleteFromGroup {
                Button("delete_completely".localized(), role: .destructive) {
                    try? viewModel.deleteCardCompletely(card)
                    cardToDeleteFromGroup = nil
                }
            }
            
            Button("cancel".localized(), role: .cancel) {
                cardToDeleteFromGroup = nil
            }
        } message: {
            Text("delete_card_choice_message".localized())
        }
    }
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let cards = viewModel.cards(for: item)
            
            if cards.isEmpty {
                emptyGroupHint
            } else {
                ForEach(cards) { card in
                    SwipeableCardRow(
                        card: card,
                        swipeState: $swipeState,
                        onEdit: { onEditCard(card) },
                        onDelete: {
                            cardToDeleteFromGroup = card
                            showDeleteCardDialog = true
                        },
                        onToggleFavourite: {
                            try? viewModel.toggleFavourite(card)
                        }
                    )
                }
            }
            
            // Кнопка "добавить карточку" — только для пользовательских групп
            if let group = item.userGroup {
                addCardButton(for: group)
            }
        }
        .padding(.leading, 16)
    }
    
    private var emptyGroupHint: some View {
        Text("no_cards_found".localized())
            .font(.captionCustom)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
    
    private func addCardButton(for group: CardGroup) -> some View {
        Button {
            onAddCard(group)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("add_new_card".localized())
                    .font(.bodyCustom)
            }
            .foregroundColor(.accent)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Handlers
    
    private func handleEdit() {
        guard let group = item.userGroup else { return }
        onEdit(group)
    }
    
    private func handleDelete() {
        guard let group = item.userGroup else { return }
        onDelete(group)
    }
}
