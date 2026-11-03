//
//  CardGroup.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

/// Пользовательская группа карточек.
/// Системные группы ("All Cards", "Favourites") НЕ хранятся здесь —
/// они рендерятся виртуально из SystemGroupType.
@Model
final class CardGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    
    /// nil для пользовательских групп.
    /// Непустое значение только для legacy-мигрированных данных
    /// или если в будущем понадобится хранить системные группы.
    var systemTypeRaw: String?
    
    var createdAt: Date
    var orderIndex: Int
    
    var cards: [Card] = []
    
    init(
        name: String,
        systemType: SystemGroupType? = nil,
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.systemTypeRaw = systemType?.rawValue
        self.createdAt = .now
        self.orderIndex = orderIndex
    }
    
    // MARK: - System type
    
    var systemType: SystemGroupType? {
        get { systemTypeRaw.flatMap(SystemGroupType.init(rawValue:)) }
        set { systemTypeRaw = newValue?.rawValue }
    }
    
    var isSystem: Bool {
        systemType != nil
    }
    
    /// Отображаемое имя (локализованное для системных, обычное для пользовательских)
    var displayName: String {
        if let type = systemType {
            return type.localizedNameKey.localized()
        }
        return name
    }
}
