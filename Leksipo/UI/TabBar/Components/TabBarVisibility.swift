//
//  TabBarVisibility.swift
//  Leksipo
//
//  Created by Егор Халиков on 07.10.2026.
//

import Foundation

/// Управляет видимостью кастомного таб-бара.
///
/// `RootView` создаёт экземпляр и передаёт через `.environment(...)`.
/// Экраны сессии (`SolveView`) скрывают таб-бар на время работы,
/// чтобы нижние элементы (SRS-кнопки оценки) не перекрывались.
@MainActor
@Observable
final class TabBarVisibility {
    var isVisible: Bool = true
}
