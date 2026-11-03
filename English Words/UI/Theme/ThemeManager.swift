//
//  ThemeManager.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI
import WidgetKit

// Управляет текущей цветовой темой приложения.

@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    private static let storageKey = "selectedTheme"
    
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.storageKey)
            
            SRSWidgetStore.saveTheme(currentTheme)
            WidgetCenter.shared.reloadAllTimelines()
            
            applyNavigationBarAppearance()
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }
    
    var colors: ThemeColors {
        ThemeColors.forTheme(currentTheme)
    }
    
    var colorScheme: ColorScheme {
        currentTheme.colorScheme
    }
    
    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppTheme.beige.rawValue
        self.currentTheme = AppTheme(rawValue: raw) ?? .beige
        SRSWidgetStore.saveTheme(currentTheme)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func setTheme(_ theme: AppTheme) {
        guard theme != currentTheme else { return }
        currentTheme = theme
    }
    
    func applyNavigationBarAppearance() {
        let c = colors
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(c.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(c.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(c.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(c.accent)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
    static let languageChanged = Notification.Name("languageChanged")
}
