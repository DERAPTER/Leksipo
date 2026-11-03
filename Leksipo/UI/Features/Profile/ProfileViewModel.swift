//
//  ProfileViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    
    struct Stats {
        var dailyGoal: Int = 20
        var todaySolved: Int = 0
        var streak: Int = 0
        var totalSolved: Int = 0
        var totalCards: Int = 0
        var userGroupsCount: Int = 0
        var favouritesCount: Int = 0
        var totalDaysGoalCompleted: Int = 0
        
        var dailyProgress: Double {
            guard dailyGoal > 0 else { return 0 }
            return min(Double(todaySolved) / Double(dailyGoal), 1.0)
        }
        
        var todayGoalCompleted: Bool {
            todaySolved >= dailyGoal
        }
    }
    
    // MARK: - State
    
    private(set) var stats = Stats()
    private(set) var activityHistory: [DailyStat] = []
    private(set) var achievements: [AchievementStatus] = []
    
    var isStatisticsExpanded = false
    var isCalendarExpanded = false
    var isAchievementsExpanded = false
    var showAllAchievements = false
    var showingGoalEditor = false
    
    var goalEditorValue: Int = 20
    
    private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let statsRepository: StatsRepository
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    private let achievementsService: AchievementsService
    private let now: () -> Date
    
    init(
        statsRepository: StatsRepository,
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        achievementsService: AchievementsService,
        now: @escaping () -> Date = { .now }
    ) {
        self.statsRepository = statsRepository
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.achievementsService = achievementsService
        self.now = now
    }
    
    // MARK: - Lifecycle
    
    func load() {
        do {
            let settings = try statsRepository.settings()
            let todayStat = try statsRepository.activity(for: now())
            
            let todaySolved = todayStat?.solvedCount ?? 0

            stats = Stats(
                dailyGoal: settings.dailyGoal,
                todaySolved: todaySolved,
                streak: try statsRepository.currentStreak(on: now()),
                totalSolved: settings.totalSolved,
                totalCards: try cardRepository.totalCount(),
                userGroupsCount: try groupRepository.userGroupsCount(),
                favouritesCount: try cardRepository.favouritesCount(),
                totalDaysGoalCompleted: try statsRepository.totalDaysGoalCompleted()
            )
            
            activityHistory = try statsRepository.activityHistory(monthsBack: -1)
            achievementsService.evaluate()
            errorMessage = nil
            achievements = achievementsService.allAchievements
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Goal editor
    
    func openGoalEditor() {
        goalEditorValue = stats.dailyGoal
        showingGoalEditor = true
    }
    
    func saveGoal(_ value: Int) {
        do {
            try statsRepository.updateDailyGoal(value)
            achievementsService.evaluate()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Calendar
    
    func isDateActive(_ date: Date) -> Bool {
        let key = DailyStat.makeKey(for: date)
        return activityHistory.first(where: { $0.dateKey == key }).map { $0.solvedCount > 0 || $0.srsReviewCount > 0 || $0.goalCompleted || $0.srsCleared } ?? false
    }
    
    // MARK: - Achievements
    
    var unlockedAchievements: [AchievementStatus] {
        achievements.filter(\.isUnlocked)
    }
    
    var achievementsPreview: [AchievementStatus] {
        Array(unlockedAchievements.prefix(10))
    }
}
