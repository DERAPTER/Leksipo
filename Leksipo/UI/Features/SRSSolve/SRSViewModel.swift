//
//  SRSViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 07.10.2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SRSViewModel {
    
    enum SRSState {
        case solving
        case completed
        case empty
    }
    
    // MARK: - Session
    
    private(set) var session: SolveSession
    private(set) var currentCard: Card?
    private var cardsByID: [UUID: Card] = [:]
    
    // MARK: - Results State
    private(set) var qualityCounts: [SRSQuality: Int] = [:]
    private(set) var nextReviewDate: Date? = nil
    private(set) var nextReviewCount: Int = 0
    
    // MARK: - UI state
    
    var isCardFlipped: Bool = false
    
    // MARK: - Errors
    
    var errorMessage: String?
    private(set) var isProcessingAnswer = false
    
    // MARK: - Dependencies
    
    private let key: SolveGroupKey = .srs
    private let cardRepository: CardRepository
    private let statsRepository: StatsRepository
    private let sessionCoordinator: SolveSessionCoordinator
    private let achievementsService: AchievementsService
    private let answerRecorder: AnswerRecordingService
    
    // MARK: - Init
    
    init(
        cardRepository: CardRepository,
        statsRepository: StatsRepository,
        sessionCoordinator: SolveSessionCoordinator,
        achievementsService: AchievementsService,
        answerRecorder: AnswerRecordingService
    ) {
        self.cardRepository = cardRepository
        self.statsRepository = statsRepository
        self.sessionCoordinator = sessionCoordinator
        self.achievementsService = achievementsService
        self.answerRecorder = answerRecorder
        
        self.session = SolveSession(groupKey: .srs, cardIDs: [])
    }
    
    // MARK: - Derived
    
    var state: SRSState {
        if session.totalCount == 0 { return .empty }
        if session.isCompletedWithoutMistakes { return .completed }
        return .solving
    }
    
    var currentProgress: Int { session.solvedCount + 1 }
    var totalProgress: Int { session.totalCount }
    var reviewedCount: Int { session.solvedCount }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        guard !isProcessingAnswer else { return }
        do {
            let loaded = try sessionCoordinator.currentSession(for: key)
            session = loaded
            restoreQualityCounts()
            errorMessage = nil
            try reloadCards()
            updateCurrentCard()
            if !session.isSolving { try calculateNextReview() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - SRS handling
    
    func intervalPreviews() -> [SRSQuality: Int] {
        guard let card = currentCard else { return [:] }
        var result: [SRSQuality: Int] = [:]
        for q in SRSQuality.allCases {
            result[q] = SRSAlgorithm.previewIntervalDays(
                quality: q.rawValue,
                currentEaseFactor: card.easeFactor,
                currentIntervalDays: card.intervalDays,
                currentRepetitions: card.repetitions
            )
        }
        return result
    }
    
    func rateCurrentCard(_ quality: SRSQuality) async {
        guard !isProcessingAnswer, !Task.isCancelled, let card = currentCard else { return }
        isProcessingAnswer = true
        defer {
            isCardFlipped = false
            updateCurrentCard()
            isProcessingAnswer = false
        }
        do {
            session = try answerRecorder.record(card: card, session: session, correct: quality.isCorrect, quality: quality)
        } catch {
            if let persistenceError = error as? PersistenceError, case .staleSession = persistenceError {
                // Не применяем ответ к другой карточке после смены дня/лимита.
                do {
                    session = try sessionCoordinator.currentSession(for: key)
                    restoreQualityCounts()
                    try reloadCards()
                } catch { errorMessage = error.localizedDescription; return }
            }
            errorMessage = error.localizedDescription
            return
        }
        errorMessage = nil
        restoreQualityCounts()
        do { try reloadCards() } catch { errorMessage = error.localizedDescription }
        _ = achievementsService.evaluate()
        if quality.isCorrect { HapticService.shared.success() } else { HapticService.shared.error() }
        if session.isCompletedWithoutMistakes {
            do { try calculateNextReview() } catch { errorMessage = error.localizedDescription }
        }
        do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
    }

    // MARK: - Card favourite
    
    func toggleFavouriteCurrentCard() {
        guard let card = currentCard else { return }
        do {
            try cardRepository.toggleFavourite(card)
            achievementsService.evaluate()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Private
    
    private func restoreQualityCounts() {
        qualityCounts = Dictionary(uniqueKeysWithValues: (session.srsQualityCounts ?? [:]).compactMap { raw, count in
            guard let value = Int(raw), let quality = SRSQuality(rawValue: value) else { return nil }
            return (quality, count)
        })
    }

    private func calculateNextReview() throws {
        let overview = try cardRepository.srsOverview(on: sessionCoordinator.currentDate, newCardsLimit: sessionCoordinator.newCardsLimit)
        nextReviewDate = overview.nextReviewDate
        nextReviewCount = overview.nextReviewCount
    }

    private func reloadCards() throws {
        let allCards = try cardRepository.fetchAll()
        cardsByID = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })
    }
    
    private func updateCurrentCard() {
        guard let id = session.currentCardID else {
            currentCard = nil
            return
        }
        currentCard = cardsByID[id]
    }
}
