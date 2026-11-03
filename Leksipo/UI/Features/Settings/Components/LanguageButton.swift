//
//  LanguageButton.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct LanguageButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(language.flagEmoji)
                    .font(.title2)
                
                Text(language.displayName)
                    .font(.bodyCustom)
                    .foregroundColor(isSelected
                                     ? themeManager.colors.accent
                                     : themeManager.colors.textPrimary)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? themeManager.colors.accent.opacity(0.15)
                          : themeManager.colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? themeManager.colors.accent : themeManager.colors.stroke,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
