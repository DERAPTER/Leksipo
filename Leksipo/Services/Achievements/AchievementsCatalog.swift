//
//  AchievementsCatalog.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

/// Статический каталог всех достижений приложения.
/// Достижения не хранятся в SwiftData — только факт их разблокировки в `UserSettings`.
enum AchievementsCatalog {
    
    static let all: [Achievement] = [
        // 📚 Карточки - создано
        Achievement(id: "cards_10",   titleKey: "achievement_cards_10",   descriptionKey: "achievement_cards_10_desc",   icon: "doc.fill",                    requiredValue: 10,   type: .cardsCreated),
        Achievement(id: "cards_50",   titleKey: "achievement_cards_50",   descriptionKey: "achievement_cards_50_desc",   icon: "doc.on.doc.fill",             requiredValue: 50,   type: .cardsCreated),
        Achievement(id: "cards_100",  titleKey: "achievement_cards_100",  descriptionKey: "achievement_cards_100_desc",  icon: "books.vertical.fill",         requiredValue: 100,  type: .cardsCreated),
        Achievement(id: "cards_250",  titleKey: "achievement_cards_250",  descriptionKey: "achievement_cards_250_desc",  icon: "globe",                       requiredValue: 250,  type: .cardsCreated),
        Achievement(id: "cards_500",  titleKey: "achievement_cards_500",  descriptionKey: "achievement_cards_500_desc",  icon: "book.fill",                   requiredValue: 500,  type: .cardsCreated),
        Achievement(id: "cards_1000", titleKey: "achievement_cards_1000", descriptionKey: "achievement_cards_1000_desc", icon: "character.book.closed.fill",  requiredValue: 1000, type: .cardsCreated),
        
        // 🎯 Решённые карточки
        Achievement(id: "solved_10",   titleKey: "achievement_solved_10",   descriptionKey: "achievement_solved_10_desc",   icon: "figure.walk",                        requiredValue: 10,   type: .cardsSolved),
        Achievement(id: "solved_50",   titleKey: "achievement_solved_50",   descriptionKey: "achievement_solved_50_desc",   icon: "graduationcap.fill",                 requiredValue: 50,   type: .cardsSolved),
        Achievement(id: "solved_100",  titleKey: "achievement_solved_100",  descriptionKey: "achievement_solved_100_desc",  icon: "star.fill",                          requiredValue: 100,  type: .cardsSolved),
        Achievement(id: "solved_250",  titleKey: "achievement_solved_250",  descriptionKey: "achievement_solved_250_desc",  icon: "crown.fill",                         requiredValue: 250,  type: .cardsSolved),
        Achievement(id: "solved_500",  titleKey: "achievement_solved_500",  descriptionKey: "achievement_solved_500_desc",  icon: "medal.fill",                         requiredValue: 500,  type: .cardsSolved),
        Achievement(id: "solved_1000", titleKey: "achievement_solved_1000", descriptionKey: "achievement_solved_1000_desc", icon: "person.crop.rectangle.stack.fill",   requiredValue: 1000, type: .cardsSolved),
        
        // Архив прежней серии: ID и описания сохраняются для полученных наград.
        Achievement(id: "streak_3",   titleKey: "achievement_streak_3",   descriptionKey: "achievement_streak_3_desc",   icon: "flame.fill",             requiredValue: 3,   type: .streak),
        Achievement(id: "streak_7",   titleKey: "achievement_streak_7",   descriptionKey: "achievement_streak_7_desc",   icon: "clock.fill",             requiredValue: 7,   type: .streak),
        Achievement(id: "streak_14",  titleKey: "achievement_streak_14",  descriptionKey: "achievement_streak_14_desc",  icon: "checkmark.seal.fill",    requiredValue: 14,  type: .streak),
        Achievement(id: "streak_21",  titleKey: "achievement_streak_21",  descriptionKey: "achievement_streak_21_desc",  icon: "calendar.circle.fill",   requiredValue: 21,  type: .streak),
        Achievement(id: "streak_30",  titleKey: "achievement_streak_30",  descriptionKey: "achievement_streak_30_desc",  icon: "bolt.fill",              requiredValue: 30,  type: .streak),
        Achievement(id: "streak_50",  titleKey: "achievement_streak_50",  descriptionKey: "achievement_streak_50_desc",  icon: "hurricane",              requiredValue: 50,  type: .streak),
        Achievement(id: "streak_100", titleKey: "achievement_streak_100", descriptionKey: "achievement_streak_100_desc", icon: "crown.fill",             requiredValue: 100, type: .streak),
        
        // Архив прежней ежедневной цели. Новые награды этого типа не выдаются.
        Achievement(id: "goal_1",   titleKey: "achievement_goal_1",   descriptionKey: "achievement_goal_1_desc",   icon: "target",                   requiredValue: 1,   type: .dailyGoalCompleted),
        Achievement(id: "goal_5",   titleKey: "achievement_goal_5",   descriptionKey: "achievement_goal_5_desc",   icon: "5.circle.fill",            requiredValue: 5,   type: .dailyGoalCompleted),
        Achievement(id: "goal_10",  titleKey: "achievement_goal_10",  descriptionKey: "achievement_goal_10_desc",  icon: "10.circle.fill",           requiredValue: 10,  type: .dailyGoalCompleted),
        Achievement(id: "goal_25",  titleKey: "achievement_goal_25",  descriptionKey: "achievement_goal_25_desc",  icon: "calendar.badge.checkmark", requiredValue: 25,  type: .dailyGoalCompleted),
        Achievement(id: "goal_50",  titleKey: "achievement_goal_50",  descriptionKey: "achievement_goal_50_desc",  icon: "figure.run",               requiredValue: 50,  type: .dailyGoalCompleted),
        Achievement(id: "goal_100", titleKey: "achievement_goal_100", descriptionKey: "achievement_goal_100_desc", icon: "laurel.leading",           requiredValue: 100, type: .dailyGoalCompleted),
        
        // ❤️ Избранное
        Achievement(id: "fav_1",  titleKey: "achievement_fav_1",  descriptionKey: "achievement_fav_1_desc",  icon: "heart.fill",         requiredValue: 1,  type: .favourites),
        Achievement(id: "fav_5",  titleKey: "achievement_fav_5",  descriptionKey: "achievement_fav_5_desc",  icon: "heart.circle.fill",  requiredValue: 5,  type: .favourites),
        Achievement(id: "fav_10", titleKey: "achievement_fav_10", descriptionKey: "achievement_fav_10_desc", icon: "heart.circle",       requiredValue: 10, type: .favourites),
        Achievement(id: "fav_25", titleKey: "achievement_fav_25", descriptionKey: "achievement_fav_25_desc", icon: "star.square.fill",   requiredValue: 25, type: .favourites),
        
        // 🎮 Группы
        Achievement(id: "group_1",  titleKey: "achievement_group_1",  descriptionKey: "achievement_group_1_desc",  icon: "folder.badge.plus",                requiredValue: 1,  type: .groupsCreated),
        Achievement(id: "group_5",  titleKey: "achievement_group_5",  descriptionKey: "achievement_group_5_desc",  icon: "folder.fill.badge.gearshape",      requiredValue: 5,  type: .groupsCreated),
        Achievement(id: "group_10", titleKey: "achievement_group_10", descriptionKey: "achievement_group_10_desc", icon: "square.stack.3d.down.right.fill",  requiredValue: 10, type: .groupsCreated),
    ] + SRSMilestone.allCases.map { milestone in
        Achievement(id: milestone.rawValue, titleKey: "achievement_\(milestone.rawValue)",
                    descriptionKey: "achievement_\(milestone.rawValue)_desc", icon: "sparkles",
                    requiredValue: 1, type: .srsMilestone)
    } + [(days: 3, icon: "timer"), (days: 7, icon: "flame.fill"),
         (days: 14, icon: "calendar.badge.checkmark"), (days: 30, icon: "bolt.fill"),
         (days: 100, icon: "crown.fill")].map { milestone in
        Achievement(id: "srs_streak_\(milestone.days)", titleKey: "achievement_srs_streak_\(milestone.days)",
                    descriptionKey: "achievement_srs_streak_\(milestone.days)_desc", icon: milestone.icon,
                    requiredValue: milestone.days, type: .srsStreak)
    } + [(count: 10, icon: "leaf.fill"), (count: 25, icon: "tree.fill"),
         (count: 50, icon: "brain.head.profile"), (count: 100, icon: "brain")].map { milestone in
        Achievement(id: "srs_long_term_\(milestone.count)", titleKey: "achievement_srs_long_term_\(milestone.count)",
                    descriptionKey: "achievement_srs_long_term_\(milestone.count)_desc", icon: milestone.icon,
                    requiredValue: milestone.count, type: .longTermCards)
    }
    
    static func achievement(withID id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
