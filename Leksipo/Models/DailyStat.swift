//
//  DailyStat.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftData

/// Одна запись = один день активности.
/// `dateKey` используется как уникальный ключ ("yyyy-MM-dd").
@Model
final class DailyStat {
    @Attribute(.unique) var dateKey: String
    var date: Date
    var solvedCount: Int
    var goalCompleted: Bool
    
    /// Выполнена ли дневная SRS-очередь, включая день без назначений.
    /// На достижения `goal_X` не влияет; в календаре показана отдельно от цели.
    var srsCleared: Bool = false
    var srsNewCardsIntroduced: Int = 0
    var srsReviewCount: Int = 0
    var srsNextDueDayKey: String? = nil
    
    init(
        date: Date,
        solvedCount: Int = 0,
        goalCompleted: Bool = false,
        srsCleared: Bool = false
    ) {
        self.dateKey = Self.makeKey(for: date)
        self.date = StudyDay.calendar.startOfDay(for: date)
        self.solvedCount = solvedCount
        self.goalCompleted = goalCompleted
        self.srsCleared = srsCleared
    }
    
    static func makeKey(for date: Date) -> String {
        StudyDay.key(for: date)
    }
}
