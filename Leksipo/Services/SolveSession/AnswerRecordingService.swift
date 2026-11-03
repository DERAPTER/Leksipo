import Foundation

@MainActor
final class AnswerRecordingService {
    private let transaction: PersistenceTransaction
    private let cards: CardRepository
    private let stats: StatsRepository
    private let coordinator: SolveSessionCoordinator

    init(transaction: PersistenceTransaction, cards: CardRepository, stats: StatsRepository, coordinator: SolveSessionCoordinator) {
        self.transaction = transaction
        self.cards = cards
        self.stats = stats
        self.coordinator = coordinator
    }

    func record(card: Card, session: SolveSession, correct: Bool, quality: SRSQuality? = nil, on suppliedDate: Date? = nil) throws -> SolveSession {
        let date = suppliedDate ?? coordinator.currentDate
        return try transaction.perform {
            try coordinator.validateCurrent(session, on: date)
            guard session.currentCardID == card.id, try cards.fetch(id: card.id) != nil else {
                throw PersistenceError.staleSession
            }
            if let quality {
                let due = try cards.fetchDueToday(on: date, newCardsLimit: coordinator.newCardsLimit)
                guard due.contains(where: { $0.id == card.id }) else { throw PersistenceError.staleSession }
                try cards.recordSRSReview(card, quality: quality.rawValue, on: date)
            } else {
                try cards.recordAnswer(card, correct: correct)
            }
            if correct { _ = try stats.recordSolved(on: date) }
            var updated = try (quality != nil || correct)
                ? coordinator.markCorrect(session, quality: quality)
                : coordinator.markWrong(session)
            if quality != nil {
                updated = try coordinator.refreshSRSQueue(updated, on: date)
                let overview = try cards.srsOverview(on: date, newCardsLimit: coordinator.newCardsLimit)
                try stats.updateSRSStatus(on: date, hasDueCards: overview.dueToday > 0, nextReviewDate: overview.nextReviewDate)
            }
            return updated
        }
    }
}
