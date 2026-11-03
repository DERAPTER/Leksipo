//
//  SelectableCardRow.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SelectableCardRow: View {
    let card: Card
    let isSelected: Bool
    let isAlreadyInGroup: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectionColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.originWord)
                        .font(.bodyCustom)
                        .foregroundColor(isAlreadyInGroup ? .textSecondary : .textPrimary)
                    
                    Text(card.languagePair.displayName)
                        .font(.caption2).foregroundColor(.textSecondary)
                    Text(card.translatedWord)
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if isAlreadyInGroup {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                        Text("already_in_group".localized())
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.accent)
                    )
                }
            }
            .padding()
            .background(rowBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(rowStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyInGroup)
    }
    
    private var selectionColor: Color {
        if isSelected { return .accent }
        if isAlreadyInGroup { return .gray }
        return .textSecondary
    }
    
    private var rowBackground: Color {
        if isAlreadyInGroup { return Color.gray.opacity(0.22) }
        if isSelected { return Color.accent.opacity(0.2) }
        return .cardBackground
    }
    
    private var rowStroke: Color {
        if isAlreadyInGroup { return Color.gray.opacity(0.3) }
        if isSelected { return .accent }
        return .stroke
    }
}
