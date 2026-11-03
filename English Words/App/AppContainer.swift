//
//  AppContainer.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

//
//  AppContainer.swift
//  English Words
//

import Foundation
import SwiftData

@MainActor
@Observable
final class AppContainer {
    
    // MARK: - Repositories
    
    let cardRepository: CardRepository
    let groupRepository: GroupRepository
    let statsRepository: StatsRepository
    
    // MARK: - Services
    
    let solveSessionStore: SolveSessionStore
    let solveSessionCoordinator: SolveSessionCoordinator
    let achievementsService: AchievementsService
    let transaction: PersistenceTransaction
    let answerRecorder: AnswerRecordingService
    let srsIntegration: SRSIntegrationService?
    var dataRevision = UUID()
    var showRestoreSuccess = false
    
    // MARK: - Init
    
    init(
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        statsRepository: StatsRepository,
        solveSessionStore: SolveSessionStore,
        solveSessionCoordinator: SolveSessionCoordinator,
        achievementsService: AchievementsService,
        transaction: PersistenceTransaction,
        answerRecorder: AnswerRecordingService,
        srsIntegration: SRSIntegrationService? = nil
    ) {
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.statsRepository = statsRepository
        self.solveSessionStore = solveSessionStore
        self.solveSessionCoordinator = solveSessionCoordinator
        self.achievementsService = achievementsService
        self.transaction = transaction
        self.answerRecorder = answerRecorder
        self.srsIntegration = srsIntegration
    }
    
    func didRestoreData() {
        achievementsService.clearNotifications()
        achievementsService.refresh()
        srsIntegration?.refresh(force: true)
        dataRevision = UUID()
        showRestoreSuccess = true
    }

    // MARK: - Factory
    
    static func live(container: ModelContainer, defaults: UserDefaults = .standard, integrateSystemServices: Bool = true) throws -> AppContainer {
        let context = container.mainContext
        
        let transaction = PersistenceTransaction(context: context)
        let cardRepo = SwiftDataCardRepository(context: context, transaction: transaction, defaults: defaults)
        let groupRepo = SwiftDataGroupRepository(context: context, transaction: transaction)
        let statsRepo = SwiftDataStatsRepository(context: context, transaction: transaction)
        
        _ = try statsRepo.settings()
        let sessionStore = SolveSessionStore(defaults: defaults, transaction: transaction)
        try sessionStore.migrateLegacySessions()
        let sessionCoordinator = SolveSessionCoordinator(
            store: sessionStore,
            cardRepository: cardRepo,
            defaults: defaults
        )
        
        let achievementsService = AchievementsService(
            statsRepository: statsRepo,
            cardRepository: cardRepo,
            groupRepository: groupRepo
        )
        
        let integration = integrateSystemServices ? SRSIntegrationService(
            cards: cardRepo, stats: statsRepo, defaults: defaults, store: .live,
            notifications: NotificationService(client: SystemSRSNotificationClient())
        ) : nil
        transaction.onCommit = { [weak integration] in integration?.refresh() }
        let app = AppContainer(
            cardRepository: cardRepo,
            groupRepository: groupRepo,
            statsRepository: statsRepo,
            solveSessionStore: sessionStore,
            solveSessionCoordinator: sessionCoordinator,
            achievementsService: achievementsService,
            transaction: transaction,
            answerRecorder: AnswerRecordingService(transaction: transaction, cards: cardRepo, stats: statsRepo, coordinator: sessionCoordinator),
            srsIntegration: integration
        )
        integration?.refresh(force: true)
        return app
    }
}
