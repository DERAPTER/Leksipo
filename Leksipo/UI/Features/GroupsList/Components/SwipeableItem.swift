//
//  SwipeableItem.swift
//  Leksipo
//
//  Created by Егор Халиков on 25.09.2026.
//

import Foundation

/// Отслеживает, какой элемент сейчас в "свайпнутом" состоянии.
/// Одновременно свайпнут может быть только один — либо группа, либо карточка.

enum SwipeableItem: Equatable {
    case none
    case group(String)   // GroupDisplayItem.id
    case card(UUID)      // Card.id
}
