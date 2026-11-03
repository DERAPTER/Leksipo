//
//  SettingsViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - State
    
    private(set) var storageSize: String = "…"
    var errorMessage: String?
    
    var showResetStatsAlert = false
    var showDeleteAllAlert = false
    var showReleaseNotesSheet = false
    var showLanguageChangeAlert = false
    
    var pendingLanguage: AppLanguage?
    
    // Состояния для бэкапа
    var backupDocument: BackupDocument?
    var isExportingBackup = false
    var isImportingBackup = false
    var showRestoreConfirmation = false
    var backupError: String?
    var showBackupSuccessAlert = false
    
    private var pendingRestoreData: Data?
    
    // MARK: - Dependencies
    
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    private let statsRepository: StatsRepository
    private let transaction: PersistenceTransaction
    private let onRestore: () -> Void
    private let solveSessionStore: SolveSessionStore
    
    init(
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        statsRepository: StatsRepository,
        solveSessionStore: SolveSessionStore,
        transaction: PersistenceTransaction,
        onRestore: @escaping () -> Void
    ) {
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.statsRepository = statsRepository
        self.solveSessionStore = solveSessionStore
        self.transaction = transaction
        self.onRestore = onRestore
    }
    
    // MARK: - Storage size
    
    func updateStorageSize() {
        storageSize = StorageSizeCalculator.calculate(
            cardRepository: cardRepository,
            groupRepository: groupRepository,
            statsRepository: statsRepository
        )
    }
    
    // MARK: - Reset stats
    
    func resetStatistics() {
        do {
            try transaction.perform {
                try statsRepository.resetAllStats()
                try solveSessionStore.clearAll()
            }
            updateStorageSize()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete all data
    
    func deleteAllData() {
        do {
            try transaction.perform {
                let cards = try cardRepository.fetchAll()
                for card in cards {
                    try cardRepository.delete(card)
                }

                let groups = try groupRepository.fetchUserGroups()
                for group in groups {
                    try groupRepository.delete(group)
                }

                try statsRepository.resetAllStats()
                try solveSessionStore.clearAll()

                try statsRepository.updateDailyGoal(20)
            }
            
            updateStorageSize()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Language
    
    func requestLanguageChange(to language: AppLanguage) {
        pendingLanguage = language
        showLanguageChangeAlert = true
    }
    
    func confirmLanguageChange() {
        guard let language = pendingLanguage else { return }
        LanguageManager.shared.setLanguage(language)
        pendingLanguage = nil
    }
    
    func cancelLanguageChange() {
        pendingLanguage = nil
    }
    
    // MARK: - Backup Actions
    
    func prepareExport(context: ModelContext) {
        do {
            let data = try BackupService.createBackup(context: context)
            self.backupDocument = BackupDocument(data: data)
            self.isExportingBackup = true
        } catch {
            self.backupError = error.localizedDescription
        }
    }
    
    func handleImportFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                self.pendingRestoreData = data
                self.showRestoreConfirmation = true
            } catch {
                self.backupError = error.localizedDescription
            }
        case .failure(let error):
            self.backupError = error.localizedDescription
        }
    }
    
    func confirmRestore(context: ModelContext) {
        guard let data = pendingRestoreData else { return }
        do {
            try BackupService.restoreBackup(from: data, context: context, transaction: transaction)
            onRestore()
            updateStorageSize()
            pendingRestoreData = nil
        } catch {
            self.backupError = error.localizedDescription
        }
    }
}
