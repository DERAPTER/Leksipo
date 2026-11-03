//
//  HapticService.swift
//  Leksipo
//
//  Created by Егор Халиков on 06.10.2026.
//

import UIKit

/// Сервис тактильного отклика.
///
/// Синглтон — относится к UI-инфраструктуре (как `ThemeManager`, `LanguageManager`).
/// По умолчанию отклик **включён**. Пользователь может отключить его в настройках
/// через ключ `hapticsEnabled` в `UserDefaults`.
@MainActor
final class HapticService {
    
    static let shared = HapticService()
    
    private static let enabledKey = "hapticsEnabled"
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {}
    
    /// Текущее значение настройки. По умолчанию — `true`.
    /// `UserDefaults.bool(forKey:)` возвращает `false`, если ключа нет,
    /// поэтому явно проверяем существование ключа.
    var isEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.enabledKey) == nil {
            return true
        }
        return defaults.bool(forKey: Self.enabledKey)
    }
    
    /// Лёгкий удар — пересечение порога при свайпе.
    func lightImpact() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }
    
    /// Средний удар — открытие sheet, смена карточки и т.п.
    func mediumImpact() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }
    
    /// Успех — правильный ответ, завершение сессии.
    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Ошибка — неправильный ответ.
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Прогрев Taptic Engine — вызывается на появлении экрана нарешивания,
    /// чтобы первый отклик был мгновенным.
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
    }
}
