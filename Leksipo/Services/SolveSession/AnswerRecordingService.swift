import Foundation

@MainActor
final class AnswerRecordingService {
    private let transaction: PersistenceTransaction
    private let cards: CardRepository
    private let stats: StatsRepository
    private let coordinator: SolveSessionCoordinator
    private let calendar: Calendar

    init(transaction: PersistenceTransaction, cards: CardRepository, stats: StatsRepository, coordinator: SolveSessionCoordinator, calendar: Calendar = StudyDay.calendar) {
        self.transaction = transaction
        self.cards = cards
        self.stats = stats
        self.coordinator = coordinator
        self.calendar = calendar
    }

    func record(card: Card, session: SolveSession, correct: Bool, quality: SRSQuality? = nil, on suppliedDate: Date? = nil) throws -> SolveSession {
        let date = suppliedDate ?? coordinator.currentDate
        return try transaction.perform {
            try coordinator.validateCurrent(session, on: date)
            guard session.currentCardID == card.id, try cards.fetch(id: card.id) != nil else {
                throw PersistenceError.staleSession
            }
            guard (session.groupKey == .srs) == (quality != nil) else {
                throw PersistenceError.staleSession
            }
            let effectiveCorrect = quality?.isCorrect ?? correct
            let previousReview = card.lastReviewDate
            let wasRelearning = card.srsRelearningPending == true
            let wasRecovering = card.srsRecoveryPending == true
            if let quality {
                let due = try cards.fetchDueToday(on: date, newCardsLimit: coordinator.newCardsLimit)
                guard due.contains(where: { $0.id == card.id }) else { throw PersistenceError.staleSession }
                try cards.recordSRSReview(card, quality: quality.rawValue, on: date)
            } else {
                try cards.recordAnswer(card, correct: correct)
            }
            if effectiveCorrect { _ = try stats.recordSolved(on: date) }
            var updated = try (quality != nil || correct)
                ? coordinator.markCorrect(session, quality: quality)
                : coordinator.markWrong(session)
            if quality != nil {
                updated = try coordinator.refreshSRSQueue(updated, on: date)
                let overview = try cards.srsOverview(on: date, newCardsLimit: coordinator.newCardsLimit)
                try stats.updateSRSStatus(on: date, hasDueCards: overview.dueToday > 0, nextReviewDate: overview.nextReviewDate)
                var milestones: Set<SRSMilestone> = [.firstReview]
                // Завершение отдельного раунда не равно выполнению всей дневной очереди.
                if overview.dueToday == 0 { milestones.insert(.firstClear) }
                if quality?.isCorrect == true && !wasRelearning {
                    if let previousReview {
                        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: previousReview),
                                                           to: calendar.startOfDay(for: date)).day ?? 0
                        if days >= 7 { milestones.insert(.weekRecall) }
                        if days >= 30 { milestones.insert(.monthRecall) }
                    }
                    if wasRecovering && card.repetitions >= 3 { milestones.insert(.recovery) }
                }
                try stats.recordSRSMilestones(milestones)
            }
            return updated
        }
    }
}
