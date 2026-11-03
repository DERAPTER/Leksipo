//
//  SolveViewModel.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SolveViewModel {
    
    enum SolveState {
        case solving
        case completedWithoutMistakes
        case completedWithMistakes
        case empty
    }
    
    enum SwipeDecision {
        case flyLeft
        case flyRight
        case reset
    }
    
    // MARK: - Session
    
    private(set) var session: SolveSession
    private(set) var currentCard: Card?
    private var cardsByID: [UUID: Card] = [:]
    
    // MARK: - UI state (свайп-режим)
    
    var offsetOfCardX: CGFloat = 0
    var offsetOfCardY: CGFloat = 0
    private(set) var percentageOfMove: Double = 0
    
    /// Текущая сторона свайпа для отслеживания смены состояния.
    /// Нужна, чтобы вибро срабатывала при каждом входе в «зелёную»/«красную» зону
    /// (в том числе при перескоке через центр), а не только один раз за жест.
    private enum SwipeSide {
        case none, left, right
    }
    private var currentSwipeSide: SwipeSide = .none
    
    // MARK: - Alerts
    
    var showUnfinishedSessionAlert = false
    var errorMessage: String?
    private(set) var isProcessingAnswer = false
    
    // MARK: - Dependencies
    
    let key: SolveGroupKey
    private let title: String
    private let cardRepository: CardRepository
    private let statsRepository: StatsRepository
    private let sessionCoordinator: SolveSessionCoordinator
    private let achievementsService: AchievementsService
    private let answerRecorder: AnswerRecordingService
    
    // MARK: - Constants
    
    private let swipeThreshold: CGFloat = 60
    private let colorThreshold: CGFloat = 30
    
    // MARK: - Init
    
    init(
        key: SolveGroupKey,
        title: String,
        cardRepository: CardRepository,
        statsRepository: StatsRepository,
        sessionCoordinator: SolveSessionCoordinator,
        achievementsService: AchievementsService,
        answerRecorder: AnswerRecordingService
    ) {
        self.key = key
        self.title = title
        self.cardRepository = cardRepository
        self.statsRepository = statsRepository
        self.sessionCoordinator = sessionCoordinator
        self.achievementsService = achievementsService
        self.answerRecorder = answerRecorder
        
        self.session = SolveSession(groupKey: key, cardIDs: [])
    }
    
    // MARK: - Derived
    
    var groupTitle: String { title }
    
    var state: SolveState {
        if session.totalCount == 0 { return .empty }
        if session.isCompletedWithMistakes { return .completedWithMistakes }
        if session.isCompletedWithoutMistakes { return .completedWithoutMistakes }
        return .solving
    }
    
    var currentProgress: Int { session.solvedCount + 1 }
    var totalProgress: Int { session.totalCount }
    var successCount: Int { session.successIDs.count }
    var failCount: Int { session.failIDs.count }
    
    var progressFraction: Double {
        let total = session.totalCount
        guard total > 0 else { return 0 }
        return Double(session.successIDs.count) / Double(total)
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        do {
            let loaded = try sessionCoordinator.currentSession(for: key)
            session = loaded
            try reloadCards()
            updateCurrentCard()
            
            if session.isUnfinished {
                showUnfinishedSessionAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Session control
    
    func continueSession() {
        showUnfinishedSessionAlert = false
    }
    
    func startOver() {
        showUnfinishedSessionAlert = false
        do {
            session = try sessionCoordinator.restartAll(for: key)
            try reloadCards()
            updateCurrentCard()
            resetOffsets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func restartFromResult() {
        do {
            session = try sessionCoordinator.restartAll(for: key)
            try reloadCards()
            updateCurrentCard()
            resetOffsets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func restartMistakesFromResult() {
        do {
            session = try sessionCoordinator.restartMistakes(session)
            updateCurrentCard()
            resetOffsets()
        } catch { errorMessage = error.localizedDescription }
    }
    
    // MARK: - Swipe handling
    
    func onDragChanged(_ value: DragGesture.Value) {
        guard !isProcessingAnswer else { return }
        offsetOfCardX = value.translation.width
        offsetOfCardY = value.translation.height
        
        let t = value.translation.width
        if t < -colorThreshold {
            percentageOfMove = max(-1, (t + colorThreshold) / 70)
        } else if t > colorThreshold {
            percentageOfMove = min(1, (t - colorThreshold) / 70)
        } else {
            percentageOfMove = 0
        }
        
        // Определяем текущую сторону
        let newSide: SwipeSide
        if t < -colorThreshold {
            newSide = .left
        } else if t > colorThreshold {
            newSide = .right
        } else {
            newSide = .none
        }
        
        // Вибро — при входе в зону или при перескоке через центр на другую сторону.
        // Уход в .none (ободок гаснет) отклика не даёт.
        if newSide != currentSwipeSide {
            if newSide != .none {
                HapticService.shared.lightImpact()
            }
            currentSwipeSide = newSide
        }
    }
    
    func onDragEnded(_ value: DragGesture.Value) -> SwipeDecision {
        guard !isProcessingAnswer else { return .reset }
        let t = value.translation.width
        let p = value.predictedEndTranslation.width
        
        if t < -swipeThreshold || p < -swipeThreshold {
            return .flyLeft
        } else if t > swipeThreshold || p > swipeThreshold {
            return .flyRight
        } else {
            return .reset
        }
    }
    
    func commitSwipe(_ decision: SwipeDecision) async {
        switch decision {
        case .flyLeft:  await commitWrong()
        case .flyRight: await commitCorrect()
        case .reset:    resetOffsets()
        }
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
    
    private func commitCorrect() async { await commitAnswer(correct: true) }

    private func commitWrong() async { await commitAnswer(correct: false) }

    private func commitAnswer(correct: Bool) async {
        guard !isProcessingAnswer, !Task.isCancelled, let card = currentCard else { return }
        isProcessingAnswer = true
        defer {
            resetOffsets()
            updateCurrentCard()
            isProcessingAnswer = false
        }
        do {
            session = try answerRecorder.record(card: card, session: session, correct: correct)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        errorMessage = nil
        _ = achievementsService.evaluate()
        if correct { HapticService.shared.success() } else { HapticService.shared.error() }
        do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
    }

    private func resetOffsets() {
        offsetOfCardX = 0
        offsetOfCardY = 0
        percentageOfMove = 0
        currentSwipeSide = .none
    }
    
    private func reloadCards() throws {
        let allCards: [Card]
        switch key {
        case .system(.allCards):
            allCards = try cardRepository.fetchAll()
        case .system(.favourites):
            allCards = try cardRepository.fetchFavourites()
        case .user(let id):
            allCards = try cardRepository.fetch(inGroup: id)
        case .srs:
            // Fallback: SRS вынесен в SRSViewModel, но на всякий случай
            // не падаем, если кто-то передаст .srs.
            allCards = try cardRepository.fetchAll()
        }
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
