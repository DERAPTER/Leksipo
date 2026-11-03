//
//  LanguageManager.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI
import WidgetKit

// Управляет языком приложения.

@Observable
final class LanguageManager {
    static let shared = LanguageManager()
    
    private static let storageKey = "appLanguage"
    
    /// Общие UserDefaults через App Group — чтобы виджет видел
    /// тот же выбранный язык, что и приложение.
    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: SRSWidgetStore.appGroupID) ?? .standard
    }
    
    var currentLanguage: AppLanguage {
        didSet {
            guard currentLanguage != oldValue else { return }
            
            // Храним в App Group (для виджета)
            Self.sharedDefaults.set(currentLanguage.rawValue, forKey: Self.storageKey)
            
            // Дублируем в standard для системных механизмов iOS
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            
            bundle = Self.loadBundle(for: currentLanguage)
            WidgetCenter.shared.reloadAllTimelines()
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    private var bundle: Bundle?
    
    private init() {
        let savedRaw = Self.sharedDefaults.string(forKey: Self.storageKey)
            ?? UserDefaults.standard.string(forKey: Self.storageKey)
        
        let lang: AppLanguage
        
        if let savedRaw, let existingLang = AppLanguage(rawValue: savedRaw) {
            lang = existingLang
        } else {
            lang = Self.determineDefaultLanguage()
            
            // Сразу сохраняем, чтобы зафиксировать выбор
            Self.sharedDefaults.set(lang.rawValue, forKey: Self.storageKey)
            UserDefaults.standard.set(lang.rawValue, forKey: Self.storageKey)
            UserDefaults.standard.set([lang.rawValue], forKey: "AppleLanguages")
        }
        
        self.currentLanguage = lang
        self.bundle = Self.loadBundle(for: lang)
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    func localizedString(_ key: String) -> String {
        bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
    
    // MARK: - Helpers
    
    /// Определяет язык по умолчанию на основе системных настроек.
    private static func determineDefaultLanguage() -> AppLanguage {
        // Получаем предпочитаемый язык системы (например, "ru-RU" или "en-US")
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return .english
        }
        
        // Извлекаем код языка (первые два символа)
        let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? String(preferredLanguage.prefix(2))
        
        switch languageCode {
        case "ru":
            return .russian
        case "en":
            return .english
        default:
            // Если системный язык не поддерживается приложением — ставим английский
            return .english
        }
    }
    
    private static func loadBundle(for language: AppLanguage) -> Bundle? {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }
}

// MARK: - String Extension

extension String {
    func localized() -> String {
        LanguageManager.shared.localizedString(self)
    }
}
