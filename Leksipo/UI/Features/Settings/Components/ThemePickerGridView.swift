//
//  ThemePickerGridView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct ThemePickerGridView: View {
    private let themeManager = ThemeManager.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                ThemeOptionCard(
                    theme: theme,
                    isSelected: themeManager.currentTheme == theme
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        themeManager.setTheme(theme)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
