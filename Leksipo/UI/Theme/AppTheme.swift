//
//  AppTheme.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case beige
    case green
    case blue
    case pink
    
    var displayNameKey: String {
        switch self {
        case .beige: return "theme_beige"
        case .green: return "theme_green"
        case .blue:  return "theme_blue"
        case .pink:  return "theme_pink"
        }
    }
    
    var displayName: String {
        //displayNameKey.localized()
        NSLocalizedString(displayNameKey, comment: "")
    }
    
    var iconName: String {
        switch self {
        case .beige: return "paintbrush.pointed.fill"
        case .green: return "leaf.fill"
        case .blue:  return "drop.fill"
        case .pink:  return "heart.fill"
        }
    }
    
    /// Цветовая схема для системы
    var colorScheme: ColorScheme {
        switch self {
        case .beige, .pink: return .light
        case .green, .blue: return .dark
        }
    }
    
    /// Три цвета для превью-карточки в настройках
    var previewColors: [Color] {
        let c = ThemeColors.forTheme(self)
        return [c.background, c.cardBackground, c.accent]
    }
}
