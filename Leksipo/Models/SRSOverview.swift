//
//  SRSOverview.swift
//  Leksipo
//
//  Created by Егор Халиков on 07.10.2026.
//

import Foundation

/// Снимок SRS-состояния для экрана обзора.
///
/// Используется на `SRSOverviewView`, а также в `SRSDueCard`
/// в списке групп нарешивания.
struct SRSOverview {
    /// Сколько карточек доступно к повторению сегодня
    /// (просроченные + новые в пределах лимита).
    let dueToday: Int
    
    /// Из них — просроченные (не новые, уже изучались, срок пришёл).
    let overdueCount: Int
    
    /// Из них — новые (ещё не оценённые, в пределах дневного лимита).
    let newCardsAvailable: Int
    
    /// Ближайшая дата в будущем, когда будут карточки к повторению.
    /// nil — если запланированных нет.
    let nextReviewDate: Date?
    
    /// Сколько карточек запланировано на `nextReviewDate`.
    let nextReviewCount: Int
}
