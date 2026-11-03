//
//  GroupChip.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct GroupChip: View {
    let group: CardGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(group.name)
                .font(.captionCustom)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accent : Color.cardBackground)
                .cornerRadius(20)
                .overlay(
                    Capsule()
                        .stroke(Color.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
