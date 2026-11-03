//
//  SystemGroupType.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Тип системной группы.
/// Используется только для UI-рендера виртуальных групп ("All Cards", "Favourites").
/// В SwiftData системные группы НЕ хранятся как отдельные CardGroup,
/// а вычисляются через предикаты.
enum SystemGroupType: String, Codable, CaseIterable {
    case allCards
    case favourites
    
    /// Ключ локализации для отображаемого имени
    var localizedNameKey: String {
        switch self {
        case .allCards:   return "all_cards"
        case .favourites: return "favourites"
        }
    }
    
    /// Иконка для UI
    var iconName: String {
        switch self {
        case .allCards:   return "square.stack.3d.up.fill"
        case .favourites: return "star.fill"
        }
    }
}
