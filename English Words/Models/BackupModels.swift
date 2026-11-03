//
//  BackupModels.swift
//  English Words
//
//  Created by Егор Халиков on 23.10.2026.
//

import Foundation

struct BackupRoot: Codable {
    // nil — старый экспорт 2.9.0; 1 — первый явно версионированный формат.
    var schemaVersion: Int? = 1
    let version: String
    let exportDate: Date
    let cards: [BackupCard]
    let groups: [BackupGroup]
    let stats: [BackupDailyStat]
    let settings: BackupUserSettings
}

struct BackupCard: Codable {
    let id: UUID
    let originWord: String
    let translatedWord: String
    let originDescription: String
    let translatedDescription: String
    let isFavourite: Bool
    let dateAdded: Date
    let correctCount: Int
    let wrongCount: Int
    let easeFactor: Double
    let intervalDays: Int
    let repetitions: Int
    let nextReviewDate: Date?
    let lastReviewDate: Date?
    let groupIDs: [UUID] // Связи с группами
}

struct BackupGroup: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    let orderIndex: Int
}

struct BackupDailyStat: Codable {
    let dateKey: String
    let date: Date
    let solvedCount: Int
    let goalCompleted: Bool
    let srsCleared: Bool
    var srsNewCardsIntroduced: Int? = nil
    var srsReviewCount: Int? = nil
    var srsNextDueDayKey: String? = nil
}

struct BackupUserSettings: Codable {
    let dailyGoal: Int
    let streak: Int
    let totalSolved: Int
    let lastActiveDate: Date
    let dailyGoalRewarded: Bool
    let srsStreak: Int
    let unlockedAchievementIDs: [String]
    let achievementUnlockDates: [String: Date]
}
