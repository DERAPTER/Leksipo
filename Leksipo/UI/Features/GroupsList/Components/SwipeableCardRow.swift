//
//  SwipeableCardRow.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SwipeableCardRow: View {
    let card: Card
    @Binding var swipeState: SwipeableItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavourite: () -> Void
    
    private var isSwiped: Bool {
        swipeState == .card(card.id)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isSwiped {
                HStack(spacing: 12) {
                    editButton
                    deleteButton
                }
                .padding(.trailing, 8)
            }
            
            CardInListView(
                card: card,
                onToggleFavourite: onToggleFavourite
            )
            .offset(x: isSwiped ? -135 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSwiped)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(swipeGesture)
        .simultaneousGesture(
            TapGesture().onEnded {
                if isSwiped {
                    withAnimation { swipeState = .none }
                }
            }
        )
    }
    
    private var editButton: some View {
        Button {
            withAnimation {
                swipeState = .none
                onEdit()
            }
        } label: {
            Image(systemName: "pencil")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.orange)
                .cornerRadius(25)
        }
        .buttonStyle(.plain)
    }
    
    private var deleteButton: some View {
        Button {
            withAnimation {
                swipeState = .none
                onDelete()
            }
        } label: {
            Image(systemName: "trash")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.red)
                .cornerRadius(25)
        }
        .buttonStyle(.plain)
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation.width
                if translation < -60, swipeState == .none {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeState = .card(card.id)
                    }
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let predicted = value.predictedEndTranslation.width
                
                if translation > 60 || predicted > 100 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeState = .none
                    }
                } else if translation < -60 || predicted < -100 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeState = .card(card.id)
                    }
                }
            }
    }
}
