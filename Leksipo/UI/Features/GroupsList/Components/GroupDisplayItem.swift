//
//  GroupDisplayItem.swift
//  Leksipo
//
//  Created by Егор Халиков on 25.09.2026.
//

import Foundation

/// То, что отображается в списке групп.
/// Системные группы — виртуальные (нет CardGroup в SwiftData),
/// пользовательские — реальные объекты.

enum GroupDisplayItem: Identifiable, Hashable {
    case system(SystemGroupType)
    case user(CardGroup)
    
    var id: String {
        switch self {
        case .system(let type): return "system_\(type.rawValue)"
        case .user(let group):  return group.id.uuidString
        }
    }
    
    var displayName: String {
        switch self {
        case .system(let type): return type.localizedNameKey.localized()
        case .user(let group):  return group.name
        }
    }
    
    var isSystem: Bool {
        if case .system = self { return true }
        return false
    }
    
    var systemType: SystemGroupType? {
        if case .system(let type) = self { return type }
        return nil
    }
    
    var userGroup: CardGroup? {
        if case .user(let group) = self { return group }
        return nil
    }
    
    // Hashable / Equatable
    static func == (lhs: GroupDisplayItem, rhs: GroupDisplayItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
