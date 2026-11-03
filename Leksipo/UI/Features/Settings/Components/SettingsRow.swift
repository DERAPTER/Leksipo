//
//  SettingsRow.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.bodyCustom)
                        .foregroundColor(themeManager.colors.textPrimary)
                    Text(description)
                        .font(.captionCustom)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
            }
            .padding()
            .background(themeManager.colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: themeManager.colors.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
