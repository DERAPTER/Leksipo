//
//  ThemeManager.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI
import UIKit
import WidgetKit

// Управляет текущей цветовой темой приложения.

@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    private static let storageKey = "selectedTheme"
    
    private(set) var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.storageKey)
            
            SRSWidgetStore.saveTheme(currentTheme)
            WidgetCenter.shared.reloadAllTimelines()
            
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
    
    @MainActor
    func setTheme(_ theme: AppTheme) {
        guard theme != currentTheme else { return }
        currentTheme = theme
        applyNavigationBarAppearance()
    }
    
    @MainActor
    func applyNavigationBarAppearance() {
        let c = colors
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(c.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(c.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(c.textPrimary)]
        
        let tint = UIColor(c.accent)
        style(UINavigationBar.appearance(), with: appearance, tint: tint)

        // UIAppearance задаёт стиль для будущих панелей. Уже открытые
        // NavigationStack используют существующие экземпляры UINavigationBar.
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                updateNavigationBars(in: window, appearance: appearance, tint: tint)
            }
        }
    }

    @MainActor
    private func updateNavigationBars(in view: UIView, appearance: UINavigationBarAppearance, tint: UIColor) {
        if let bar = view as? UINavigationBar {
            style(bar, with: appearance, tint: tint)
        } else {
            for subview in view.subviews {
                updateNavigationBars(in: subview, appearance: appearance, tint: tint)
            }
        }
    }

    @MainActor
    private func style(_ bar: UINavigationBar, with appearance: UINavigationBarAppearance, tint: UIColor) {
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.compactScrollEdgeAppearance = appearance
        bar.tintColor = tint
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
    static let languageChanged = Notification.Name("languageChanged")
}
