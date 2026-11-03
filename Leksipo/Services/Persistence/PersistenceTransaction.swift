import Foundation
import SwiftData

/// Синхронная граница изменения общего контекста. Вложенные операции
/// репозиториев сохраняются только вместе с внешней операцией.
@MainActor
final class PersistenceTransaction {
    let context: ModelContext
    var onCommit: (() -> Void)?
    private var depth = 0
    private var snapshots: [ObjectIdentifier: () -> Void] = [:]
    private let save: (ModelContext) throws -> Void

    init(context: ModelContext, save: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        self.context = context
        self.save = save
    }

    private func remember(_ model: AnyObject, restore: @escaping () -> Void) {
        let id = ObjectIdentifier(model)
        guard !context.insertedModelsArray.contains(where: { ObjectIdentifier($0) == id }) else { return }
        if snapshots[id] == nil { snapshots[id] = restore }
    }

    func perform<T>(_ operation: () throws -> T) throws -> T {
        if depth > 0 { return try operation() }
        // Не откатываем и не сохраняем чужой незавершённый ввод.
        guard !context.hasChanges else { throw PersistenceError.pendingChanges }
        let autosave = context.autosaveEnabled
        context.autosaveEnabled = false
        depth = 1
        defer {
            snapshots.removeAll()
            depth = 0
            context.autosaveEnabled = autosave
        }
        do {
            let result = try operation()
            let changed = context.hasChanges
            try save(context)
            // Внешние представления получают только уже зафиксированное состояние.
            snapshots.removeAll()
            depth = 0
            if changed { onCommit?() }
            return result
        } catch {
            context.rollback()
            for restore in snapshots.values { restore() }
            context.rollback()
            throw error
        }
    }
}

enum PersistenceError: LocalizedError {
    case pendingChanges
    case invalidMigration
    case invalidBackup
    case unsupportedBackup
    case staleSession

    var errorDescription: String? {
        switch self {
        case .pendingChanges: return "persistence_pending_changes".localized()
        case .invalidMigration: return "migration_invalid_data".localized()
        case .invalidBackup: return "backup_invalid_data".localized()
        case .unsupportedBackup: return "backup_unsupported_version".localized()
        case .staleSession: return "session_changed_retry".localized()
        }
    }
}

// SwiftData rollback восстанавливает хранилище, но наблюдаемые модели могут
// удерживать закэшированные значения. Снимки берутся только для затронутых объектов.
extension PersistenceTransaction {
    func track(_ card: Card) {
        let value = BackupCard(id: card.id, originWord: card.originWord, translatedWord: card.translatedWord,
                               originDescription: card.originDescription, translatedDescription: card.translatedDescription,
                               isFavourite: card.isFavourite, dateAdded: card.dateAdded, correctCount: card.correctCount,
                               wrongCount: card.wrongCount, easeFactor: card.easeFactor, intervalDays: card.intervalDays,
                               repetitions: card.repetitions, nextReviewDate: card.nextReviewDate,
                               lastReviewDate: card.lastReviewDate, groupIDs: [])
        let groups = card.groups
        remember(card) {
            card.id = value.id
            card.originWord = value.originWord
            card.translatedWord = value.translatedWord
            card.originDescription = value.originDescription
            card.translatedDescription = value.translatedDescription
            card.isFavourite = value.isFavourite
            card.dateAdded = value.dateAdded
            card.correctCount = value.correctCount
            card.wrongCount = value.wrongCount
            card.easeFactor = value.easeFactor
            card.intervalDays = value.intervalDays
            card.repetitions = value.repetitions
            card.nextReviewDate = value.nextReviewDate
            card.lastReviewDate = value.lastReviewDate
            card.groups = groups
        }
    }

    func track(_ group: CardGroup) {
        let id = group.id, name = group.name, date = group.createdAt, order = group.orderIndex
        let systemType = group.systemTypeRaw, cards = group.cards
        remember(group) {
            group.id = id
            group.name = name
            group.createdAt = date
            group.orderIndex = order
            group.systemTypeRaw = systemType
            group.cards = cards
        }
    }

    func track(_ settings: UserSettings) {
        let goal = settings.dailyGoal, streak = settings.streak, total = settings.totalSolved
        let last = settings.lastActiveDate, rewarded = settings.dailyGoalRewarded, srs = settings.srsStreak
        let ids = settings.unlockedAchievementIDs, dates = settings.achievementUnlockDates
        let sessions = settings.solveSessionsData, migrated = settings.legacyMigrationCompleted
        remember(settings) {
            settings.dailyGoal = goal
            settings.streak = streak
            settings.totalSolved = total
            settings.lastActiveDate = last
            settings.dailyGoalRewarded = rewarded
            settings.srsStreak = srs
            settings.unlockedAchievementIDs = ids
            settings.achievementUnlockDates = dates
            settings.solveSessionsData = sessions
            settings.legacyMigrationCompleted = migrated
        }
    }

    func track(_ stat: DailyStat) {
        let key = stat.dateKey, date = stat.date, count = stat.solvedCount
        let goal = stat.goalCompleted, srs = stat.srsCleared
        let introduced = stat.srsNewCardsIntroduced, reviewed = stat.srsReviewCount, nextDue = stat.srsNextDueDayKey
        remember(stat) {
            stat.dateKey = key
            stat.date = date
            stat.solvedCount = count
            stat.goalCompleted = goal
            stat.srsCleared = srs
            stat.srsNewCardsIntroduced = introduced
            stat.srsReviewCount = reviewed
            stat.srsNextDueDayKey = nextDue
        }
    }
}
