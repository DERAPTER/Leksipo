//
//  ThemeOptionCard.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//


import SwiftUI

struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.previewColors[index])
                            .frame(width: 35, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.8)
                            )
                    }
                }
                .padding(.top, 12)
                
                Text(theme.displayName)
                    .font(.bodyCustom)
                    .foregroundColor(isSelected
                                     ? themeManager.colors.accent
                                     : themeManager.colors.textSecondary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(themeManager.colors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? themeManager.colors.accent : themeManager.colors.stroke,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
