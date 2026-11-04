import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    enum CardFilter: String, Identifiable, CaseIterable {
        case all, new, learning, longTerm, attention
        var id: String { rawValue }
        var title: String { "progress_filter_\(rawValue)".localized() }

        func includes(_ card: Card) -> Bool {
            switch self {
            case .all: return true
            case .new: return card.isNewInSRS
            case .learning: return !card.isNewInSRS && card.intervalDays < 30
            case .longTerm: return !card.isNewInSRS && card.intervalDays >= 30
            case .attention:
                return card.totalAttempts >= 5 && card.wrongCount >= 3 &&
                    Double(card.wrongCount) / Double(card.totalAttempts) >= 0.3
            }
        }
    }

    struct LanguageProgress: Identifiable {
        let pair: StudyLanguagePair
        let cards: [Card]
        var id: StudyLanguagePair { pair }
        var newCount: Int { cards.filter(\.isNewInSRS).count }
        var longTermCount: Int { cards.filter { CardFilter.longTerm.includes($0) }.count }
        var learningCount: Int { cards.count - newCount - longTermCount }
    }

    struct DayProgress: Identifiable {
        let date: Date
        let id: String
        let correctAnswers: Int
        let srsReviews: Int
    }

    private(set) var srsStreak = 0
    private(set) var languages: [LanguageProgress] = []
    private(set) var week: [DayProgress] = []
    private(set) var history: [DayProgress] = []
    private(set) var activityHistory: [DailyStat] = []
    private(set) var achievements: [AchievementStatus] = []
    private(set) var errorMessage: String?
    private(set) var hasLoaded = false
    private var allCards: [Card] = []
    var showAllAchievements = false
    var showHistory = false

    private let statsRepository: StatsRepository
    private let cardRepository: CardRepository
    private let achievementsService: AchievementsService
    private let now: () -> Date
    private let calendar: Calendar

    init(statsRepository: StatsRepository, cardRepository: CardRepository, groupRepository: GroupRepository,
         achievementsService: AchievementsService, now: @escaping () -> Date = { .now }, calendar: Calendar = StudyDay.calendar) {
        self.statsRepository = statsRepository
        self.cardRepository = cardRepository
        self.achievementsService = achievementsService
        self.now = now
        self.calendar = calendar
    }

    func load() {
        do {
            let date = now()
            let cards = try cardRepository.fetchAll()
            let records = try statsRepository.activityHistory(monthsBack: -1)
            let streak = try statsRepository.currentSRSStreak(on: date)
            let todayKey = StudyDay.key(for: date, calendar: calendar)
            let byDay = Dictionary(uniqueKeysWithValues: records.map { ($0.dateKey, $0) })
            let days = (0..<7).reversed().compactMap { offset -> DayProgress? in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) else { return nil }
                let key = StudyDay.key(for: day, calendar: calendar)
                return DayProgress(date: day, id: key, correctAnswers: byDay[key]?.solvedCount ?? 0,
                                   srsReviews: byDay[key]?.srsReviewCount ?? 0)
            }
            let fullHistory = records.filter {
                $0.dateKey <= todayKey && ($0.solvedCount > 0 || $0.srsReviewCount > 0)
            }.compactMap { record -> DayProgress? in
                guard let day = StudyDay.date(for: record.dateKey, calendar: calendar) else { return nil }
                return DayProgress(date: day, id: record.dateKey, correctAnswers: record.solvedCount, srsReviews: record.srsReviewCount)
            }.sorted { $0.id > $1.id }
            let languageProgress = Dictionary(grouping: cards, by: \.languagePair).map {
                LanguageProgress(pair: $0.key, cards: $0.value)
            }.sorted {
                if $0.pair.displayName != $1.pair.displayName { return $0.pair.displayName.localizedStandardCompare($1.pair.displayName) == .orderedAscending }
                return $0.pair.learning.code + $0.pair.translation.code < $1.pair.learning.code + $1.pair.translation.code
            }
            allCards = cards
            activityHistory = records
            history = fullHistory
            week = days
            languages = languageProgress
            srsStreak = streak
            achievementsService.evaluate()
            achievements = achievementsService.allAchievements
            hasLoaded = true
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    var weeklyCorrectAnswers: Int { week.reduce(0) { $0 + $1.correctAnswers } }
    var weeklySRSReviews: Int { week.reduce(0) { $0 + $1.srsReviews } }
    var attentionCount: Int { allCards.filter { CardFilter.attention.includes($0) }.count }
    var nextAchievement: AchievementStatus? {
        if let firstReview = achievements.first(where: { $0.id == SRSMilestone.firstReview.rawValue && !$0.isUnlocked }) {
            return firstReview
        }
        return achievements.filter { !$0.isUnlocked && !$0.achievement.isRetired && $0.achievement.isFeatured }.sorted {
            if $0.progress != $1.progress { return $0.progress > $1.progress }
            if $0.achievement.requiredValue != $1.achievement.requiredValue { return $0.achievement.requiredValue < $1.achievement.requiredValue }
            return $0.id < $1.id
        }.first
    }
    var latestAchievement: AchievementStatus? {
        achievements.filter { $0.isUnlocked && !$0.achievement.isRetired }.sorted {
            if $0.unlockedDate != $1.unlockedDate { return ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }
            return $0.id < $1.id
        }.first
    }

    func cards(for pair: StudyLanguagePair?, filter: CardFilter) -> [Card] {
        allCards.filter { (pair == nil || $0.languagePair == pair) && filter.includes($0) }.sorted {
            if filter == .attention && $0.successRate != $1.successRate { return $0.successRate < $1.successRate }
            let order = $0.originWord.localizedStandardCompare($1.originWord)
            return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
        }
    }

    func isDateActive(_ date: Date) -> Bool {
        let key = StudyDay.key(for: date, calendar: calendar)
        return history.contains { $0.id == key }
    }
}
