//
//  SwipeableGroupHeader.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SwipeableGroupHeader: View {
    let item: GroupDisplayItem
    let cardCount: Int
    let isExpanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Binding var swipeState: SwipeableItem
    
    private var isSwiped: Bool {
        swipeState == .group(item.id)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isSwiped && !item.isSystem {
                HStack(spacing: 12) {
                    editButton
                    deleteButton
                }
                .padding(.trailing, 8)
            }
            
            content
                .offset(x: isSwiped ? -135 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSwiped)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(swipeGesture)
        .simultaneousGesture(
            TapGesture().onEnded {
                if isSwiped {
                    withAnimation { swipeState = .none }
                } else {
                    onTap()
                }
            }
        )
    }
    
    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.titleCustom)
                    .foregroundColor(.textPrimary)
                if let group = item.userGroup {
                    Text(group.languagePair.displayName)
                        .font(.captionCustom)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Spacer()
            
            Text("\(cardCount)")
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
            
            Image(systemName: "chevron.down")
                .font(.body)
                .foregroundColor(.textSecondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
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
                guard !item.isSystem else { return }
                let translation = value.translation.width
                if translation < -60, swipeState == .none {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeState = .group(item.id)
                    }
                }
            }
            .onEnded { value in
                guard !item.isSystem else { return }
                let translation = value.translation.width
                let predicted = value.predictedEndTranslation.width
                
                if translation > 60 || predicted > 100 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeState = .none
                    }
                } else if translation < -60 || predicted < -100 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeState = .group(item.id)
                    }
                }
            }
    }
}
