//
//  AppScreen.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

enum AppScreen: CaseIterable {
    case cardsGroups
    case solveCards
    case srsReview
    case profile
    
    var titleKey: String {
        switch self {
        case .cardsGroups: return "tab_cards"
        case .solveCards:  return "tab_solve"
        case .srsReview:   return "tab_srs"
        case .profile:     return "tab_profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .cardsGroups: return "square.stack.3d.up.fill"
        case .solveCards:  return "play.circle.fill"
        case .srsReview:   return "clock.arrow.circlepath"
        case .profile:     return "chart.bar.fill"
        }
    }
    
    var title: String {
        titleKey.localized()
    }
}
