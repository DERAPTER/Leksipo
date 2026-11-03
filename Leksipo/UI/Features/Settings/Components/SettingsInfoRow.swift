//
//  SettingsInfoRow.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.colors.textSecondary)
                .frame(width: 32)
            
            Text(title)
                .font(.bodyCustom)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.bodyCustom)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding()
        .background(themeManager.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: themeManager.colors.shadowColor, radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}
