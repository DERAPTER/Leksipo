import Foundation
import SwiftData
import Testing
@testable import English_Words

@Suite("Прогресс обучения")
@MainActor
struct ProfileProgressTests {
    private func fixture() throws -> ProgressFixture { try ProgressFixture() }

    @Test("Категории по языкам не пересекаются, граница долгосрочного интервала — 30 дней")
    func languageStagesAndSharedCards() throws {
        let f = try fixture()
        let french = StudyLanguagePair(learning: try #require(StudyLanguage(code: "fr")), translation: .russian)
        let g1 = try f.repos.group.create(name: "One", languagePair: french)
        let g2 = try f.repos.group.create(name: "Two", languagePair: french)
        let fresh = try f.repos.card.create(origin: "new", translated: "новая", groups: [g1, g2])
        let learning = try f.repos.card.create(origin: "learning", translated: "в работе", groups: [g1])
        let mature = try f.repos.card.create(origin: "mature", translated: "зрелая", groups: [g1])
        let english = try f.repos.card.create(origin: "english", translated: "английский", groups: [])
        learning.lastReviewDate = f.date
        learning.intervalDays = 29
        mature.lastReviewDate = f.date
        mature.intervalDays = 30
        // Одного интервала без факта SRS-ответа недостаточно, чтобы считать карточку изученной.
        fresh.intervalDays = 30
        try f.repos.container.mainContext.save()
        f.vm.load()
        let progress = try #require(f.vm.languages.first { $0.pair == french })
        #expect(progress.cards.count == 3)
        #expect(progress.newCount == 1 && progress.learningCount == 1 && progress.longTermCount == 1)
        #expect(f.vm.languages.count == 2)
        #expect(f.vm.cards(for: french, filter: .longTerm).map(\.id) == [mature.id])
        #expect(f.vm.cards(for: nil, filter: .all).count == 4)
        #expect(f.vm.cards(for: .legacy, filter: .new).map(\.id) == [english.id])
    }

    @Test("Частые ошибки требуют достаточного числа попыток и не меняют порядок SRS")
    func attentionBoundary() throws {
        let f = try fixture()
        let few = try f.card("few"), frequent = try f.card("frequent"), rare = try f.card("rare")
        few.wrongCount = 3; few.correctCount = 1
        frequent.wrongCount = 3; frequent.correctCount = 7
        rare.wrongCount = 3; rare.correctCount = 8
        try f.repos.container.mainContext.save()
        f.vm.load()
        #expect(f.vm.attentionCount == 1)
        #expect(f.vm.cards(for: nil, filter: .attention).map(\.id) == [frequent.id])
        #expect(frequent.lastReviewDate == nil && frequent.nextReviewDate == nil)
    }

    @Test("Неделя содержит семь гражданских дней, нули и правильные подписи на границах DST")
    func weekUsesStudyDays() throws {
        let f = try fixture()
        let yesterday = try #require(f.calendar.date(byAdding: .day, value: -1, to: f.date))
        let old = try #require(f.calendar.date(byAdding: .day, value: -7, to: f.date))
        let future = try #require(f.calendar.date(byAdding: .day, value: 1, to: f.date))
        try f.stat(yesterday, correct: 5, reviews: 8)
        try f.stat(f.date, correct: 2, reviews: 3)
        try f.stat(old, correct: 40, reviews: 50)
        try f.stat(future, correct: 99, reviews: 99)
        f.vm.load()
        #expect(f.vm.week.count == 7)
        #expect(Set(f.vm.week.map(\.id)).count == 7)
        #expect(f.vm.week.last?.id == StudyDay.key(for: f.date, calendar: f.calendar))
        #expect(f.vm.weeklyCorrectAnswers == 7 && f.vm.weeklySRSReviews == 11)
        #expect(f.vm.week.filter { $0.correctAnswers == 0 }.count == 5)
        #expect(f.vm.history.count == 3)
        #expect(!f.vm.isDateActive(future))
    }

    @Test("Пустой SRS-день сохраняет серию, но не выдаётся за занятие")
    func emptyDayIsNotActivity() throws {
        let f = try fixture()
        let stat = DailyStat(date: f.date, srsCleared: true)
        stat.dateKey = StudyDay.key(for: f.date, calendar: f.calendar)
        f.repos.container.mainContext.insert(stat)
        try f.repos.container.mainContext.save()
        f.vm.load()
        #expect(f.vm.history.isEmpty && !f.vm.isDateActive(f.date))
        #expect(f.vm.weeklyCorrectAnswers == 0 && f.vm.weeklySRSReviews == 0)
    }

    @Test("История включает ошибочные SRS-ответы без правильных ответов")
    func wrongSRSAnswersRemainVisible() throws {
        let f = try fixture()
        try f.stat(f.date, correct: 0, reviews: 3)
        f.vm.load()
        #expect(f.vm.history.count == 1 && f.vm.isDateActive(f.date))
        #expect(f.vm.weeklyCorrectAnswers == 0 && f.vm.weeklySRSReviews == 3)
    }

    @Test("Архивные награды сохраняют ID и дату; новые цели не открывают их повторно")
    func preservesLegacyAwards() throws {
        let f = try fixture()
        let settings = try f.repos.stats.settings()
        settings.unlock("goal_1", on: f.date)
        settings.unlock("streak_7", on: f.date)
        settings.streak = 100
        try f.repos.container.mainContext.save()
        _ = try f.repos.stats.recordSolved(on: f.date)
        f.vm.load()
        let old = try #require(f.vm.achievements.first { $0.id == "goal_1" })
        #expect(old.isUnlocked && old.unlockedDate == f.date && old.achievement.isRetired)
        #expect(!settings.isUnlocked("goal_5") && !settings.isUnlocked("streak_100"))
        #expect(f.vm.nextAchievement?.achievement.isRetired == false)
        #expect(f.vm.latestAchievement == nil)
    }

    @Test("Награды долгосрочного повторения и SRS имеют независимые новые пороги")
    func newAchievementThresholds() throws {
        let snapshot = AchievementsSnapshot(cardsCreated: 0, cardsSolved: 0, streak: 100,
            daysGoalCompleted: 100, favouritesCount: 0, userGroupsCount: 0, srsStreak: 7, longTermCards: 25)
        let earned = Set(AchievementsEvaluator.newlyUnlocked(snapshot: snapshot, alreadyUnlocked: []).map(\.id))
        #expect(earned == ["srs_streak_3", "srs_streak_7", "srs_long_term_10", "srs_long_term_25"])
        let status = AchievementStatus(achievement: try #require(AchievementsCatalog.achievement(withID: "srs_long_term_50")),
                                       isUnlocked: false, unlockedDate: nil, currentValue: 25)
        #expect(status.progressValue == 25 && status.progress == 0.5)
    }

    @Test("Сервис считает текущую SRS-серию по датам, а не по архивному кешу")
    func achievementServiceUsesCurrentSRSStreak() throws {
        let f = try fixture()
        let settings = try f.repos.stats.settings()
        settings.srsStreak = 100
        try f.repos.container.mainContext.save()
        f.achievements.evaluate()
        #expect(!settings.isUnlocked("srs_streak_3"))
        for offset in -2...0 {
            let day = try #require(f.calendar.date(byAdding: .day, value: offset, to: f.date))
            let stat = DailyStat(date: day, srsCleared: true)
            stat.dateKey = StudyDay.key(for: day, calendar: f.calendar)
            f.repos.container.mainContext.insert(stat)
        }
        try f.repos.container.mainContext.save()
        let stats = SwiftDataStatsRepository(context: f.repos.container.mainContext, calendar: f.calendar, now: { f.date })
        let service = AchievementsService(statsRepository: stats, cardRepository: f.repos.card, groupRepository: f.repos.group, now: { f.date })
        service.evaluate()
        #expect(settings.isUnlocked("srs_streak_3") && !settings.isUnlocked("srs_streak_7"))
        #expect(settings.achievementUnlockDates["srs_streak_3"] == f.date)
    }

    @Test("Пустой профиль содержит неделю и достижение без ложного прогресса")
    func emptyProgress() throws {
        let f = try fixture()
        f.vm.load()
        #expect(f.vm.hasLoaded && f.vm.errorMessage == nil)
        #expect(f.vm.languages.isEmpty && f.vm.week.count == 7 && f.vm.history.isEmpty)
        #expect(f.vm.attentionCount == 0)
        #expect(f.vm.nextAchievement?.progress == 0)
        #expect(f.vm.latestAchievement == nil)
    }

    @Test("Ближайшая цель связана с SRS даже при почти достигнутом счётчике ответов")
    func nextMilestonePrioritizesSRS() throws {
        let f = try fixture()
        let settings = try f.repos.stats.settings()
        settings.totalSolved = 249
        try f.repos.container.mainContext.save()
        f.vm.load()
        #expect(f.vm.nextAchievement?.achievement.type == .srsMilestone)
        #expect(f.vm.nextAchievement?.id == "srs_first_review")
    }

    @Test("Удаление карточки и смена её языка обновляют разбиение после загрузки")
    func reloadReflectsCardChanges() throws {
        let f = try fixture()
        let card = try f.card("one")
        f.vm.load()
        #expect(f.vm.languages.count == 1)
        card.languagePair = StudyLanguagePair(learning: try #require(StudyLanguage(code: "de")), translation: .russian)
        try f.repos.container.mainContext.save()
        f.vm.load()
        #expect(f.vm.languages.first?.pair.learning.code == "de")
        try f.repos.card.delete(card)
        f.vm.load()
        #expect(f.vm.languages.isEmpty)
    }
}

@MainActor
private final class ProgressFixture {
    let repos: TestContainer.Repositories
    let achievements: AchievementsService
    let vm: ProfileViewModel
    let date: Date
    let calendar: Calendar

    init() throws {
        repos = try TestContainer.makeRepositories()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        self.calendar = calendar
        date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 12)))
        let date = self.date
        achievements = AchievementsService(statsRepository: repos.stats, cardRepository: repos.card,
                                          groupRepository: repos.group, now: { date })
        vm = ProfileViewModel(statsRepository: repos.stats, cardRepository: repos.card, groupRepository: repos.group,
                              achievementsService: achievements, now: { date }, calendar: calendar)
    }

    func card(_ word: String) throws -> Card { try repos.card.create(origin: word, translated: "перевод", groups: []) }

    func stat(_ date: Date, correct: Int, reviews: Int) throws {
        let stat = DailyStat(date: date, solvedCount: correct)
        stat.dateKey = StudyDay.key(for: date, calendar: calendar)
        stat.srsReviewCount = reviews
        repos.container.mainContext.insert(stat)
        try repos.container.mainContext.save()
    }
}
