//
//  AppLanguage.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case russian = "ru"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .english: return "🇬🇧"
        case .russian: return "🇷🇺"
        }
    }
    
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}
