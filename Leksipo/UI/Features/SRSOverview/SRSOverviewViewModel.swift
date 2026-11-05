//
//  SRSOverviewViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 07.10.2026.
//

import Foundation

@MainActor
@Observable
final class SRSOverviewViewModel {
    
    private(set) var overview: SRSOverview?
    private(set) var srsStreak: Int = 0
    private(set) var isSRSClearedToday: Bool = false
    private(set) var errorMessage: String?
    
    private let cardRepository: CardRepository
    private let statsRepository: StatsRepository
    private let defaults: UserDefaults
    private let now: () -> Date
    
    init(cardRepository: CardRepository, statsRepository: StatsRepository, defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }) {
        self.cardRepository = cardRepository
        self.statsRepository = statsRepository
        self.defaults = defaults
        self.now = now
    }
    
    // MARK: - Loading
    
    func load() {
        let limit = defaults.integer(forKey: "srsNewCardsPerDay")
        let effectiveLimit = limit > 0 ? limit : 20
        do {
            overview = try cardRepository.srsOverview(
                on: now(),
                newCardsLimit: effectiveLimit
            )
                
            if let overview {
                try statsRepository.updateSRSStatus(on: now(), hasDueCards: overview.dueToday > 0, nextReviewDate: overview.nextReviewDate)
            }
            srsStreak = try statsRepository.currentSRSStreak(on: now())
            errorMessage = nil
    
            // Проверяем, разгребен ли SRS сегодня
            let todayStat = try statsRepository.activity(for: now())
            isSRSClearedToday = todayStat?.srsCleared ?? false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Date formatting

    func formattedNextDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        
        if calendar.isDateInTomorrow(date) {
            return "srs_overview_tomorrow".localized()
        }
        
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        
        if days <= 6 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date).capitalized
        }
        
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}
