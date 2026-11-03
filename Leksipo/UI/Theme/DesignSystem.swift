//
//  DesignSystem.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

// MARK: - Semantic Colors
//
// Эти extension'ы дают доступ к цветам текущей темы из любого места UI.
// Обновляются автоматически при смене темы через @Observable ThemeManager.

extension Color {
    static var appBackground: Color  { ThemeManager.shared.colors.background }
    static var cardBackground: Color { ThemeManager.shared.colors.cardBackground }
    static var textPrimary: Color    { ThemeManager.shared.colors.textPrimary }
    static var textSecondary: Color  { ThemeManager.shared.colors.textSecondary }
    static var accent: Color         { ThemeManager.shared.colors.accent }
    static var stroke: Color         { ThemeManager.shared.colors.stroke }
    static var shadowColor: Color    { ThemeManager.shared.colors.shadowColor }
    static var correct: Color        { ThemeManager.shared.colors.correct }
    static var wrong: Color          { ThemeManager.shared.colors.wrong }
}

// MARK: - Custom Fonts

extension Font {
    static let largeTitleCustom = Font.largeTitle.weight(.bold)
    static let titleCustom      = Font.title2.weight(.semibold)
    static let bodyCustom       = Font.body
    static let captionCustom    = Font.caption.weight(.medium)
}
