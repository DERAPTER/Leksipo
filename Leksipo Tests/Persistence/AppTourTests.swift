import Foundation
import Testing
@testable import English_Words

@MainActor
struct AppTourTests {
    @Test("Учебные ответы остаются в экскурсии, сохранение переносит только содержимое")
    func practiceAndSave() async throws {
        let tour = try AppTour(introduce: true)
        let suite = "Leksipo.TourTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = try TestContainer.makeContainer()
        let live = try AppContainer.live(container: model, defaults: defaults, integrateSystemServices: false)
        _ = try live.groupRepository.create(name: "Example")

        tour.selectTab(.profile)
        #expect(tour.step == .introduction)
        #expect(tour.screen == .cardsGroups)
        tour.advance(from: .introduction, to: .createGroup)
        let group = try tour.sandbox.groupRepository.create(name: "Example")
        tour.createdGroup(group.id)
        let card = try tour.sandbox.cardRepository.create(origin: "hello", translated: "привет", groups: [group])
        tour.advance(from: .addCard, to: .practiceTab)
        tour.selectTab(.solveCards)
        tour.beginPractice(.user(group.id))
        tour.advance(from: .flipCard, to: .answerCard)

        let session = try tour.sandbox.solveSessionCoordinator.currentSession(for: .user(group.id))
        _ = try tour.sandbox.answerRecorder.record(card: card, session: session, correct: true)
        #expect(card.correctCount == 1)
        #expect(try live.cardRepository.totalCount() == 0)
        #expect(try live.statsRepository.settings().totalSolved == 0)

        tour.advance(from: .answerCard, to: .reviewsTab)
        tour.selectTab(.srsReview)
        tour.advance(from: .reviews, to: .reviewFlip)
        tour.leaveReview()
        #expect(tour.step == .reviews)
        tour.selectTab(.profile)
        #expect(tour.screen == .srsReview)
        #expect(card.isNewInSRS)

        let review = SRSViewModel(cardRepository: tour.sandbox.cardRepository,
                                  statsRepository: tour.sandbox.statsRepository,
                                  sessionCoordinator: tour.sandbox.solveSessionCoordinator,
                                  achievementsService: tour.sandbox.achievementsService,
                                  answerRecorder: tour.sandbox.answerRecorder)
        review.onAppear()
        #expect(review.currentCard?.id == card.id)
        tour.advance(from: .reviews, to: .reviewFlip)
        tour.reviewCardChanged(isFlipped: true)
        #expect(tour.step == .reviewRate)
        await review.rateCurrentCard(.forgot)
        #expect(review.state == .solving)
        #expect(review.currentCard?.id == card.id)
        tour.reviewCardChanged(isFlipped: false)
        #expect(tour.step == .reviewFlip)
        tour.reviewCardChanged(isFlipped: true)
        await review.rateCurrentCard(.remembered)
        #expect(review.state == .completed)
        #expect(review.qualityCounts[.forgot] == 1)
        let nextDate = try #require(review.nextReviewDate)
        #expect(nextDate > tour.sandbox.solveSessionCoordinator.currentDate)
        #expect(review.nextReviewCount == 1)
        #expect(!card.isNewInSRS)
        #expect(try live.statsRepository.settings().totalSolved == 0)

        tour.completedReview()
        #expect(tour.step == .reviewResult)
        tour.leaveReview()
        tour.selectTab(.profile)
        tour.advance(from: .profile, to: .finish)
        try tour.saveGroup(to: live)
        try tour.saveGroup(to: live)

        let storedGroups = try live.groupRepository.fetchUserGroups()
        let saved = try #require(storedGroups.first { $0.name == "Example (2)" })
        let copied = try #require(saved.cards.first)
        #expect(storedGroups.count == 2)
        #expect(copied.originWord == "hello")
        #expect(copied.translatedWord == "привет")
        #expect(copied.isNewInSRS)
        #expect(copied.correctCount == 0)
        #expect(try live.statsRepository.settings().totalSolved == 0)
    }
}
