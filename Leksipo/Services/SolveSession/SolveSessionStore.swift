import Foundation
import SwiftData

/// В приложении очередь сохраняется в той же транзакции SwiftData, что и ответ.
/// UserDefaults остаётся источником однократного переноса старых сессий.
@MainActor
final class SolveSessionStore {
    private let defaults: UserDefaults
    private let transaction: PersistenceTransaction?
    private let storageKey = "solve_sessions_v1"

    init(defaults: UserDefaults = .standard, transaction: PersistenceTransaction? = nil) {
        self.defaults = defaults
        self.transaction = transaction
    }

    func migrateLegacySessions() throws {
        guard let transaction else { return }
        try transaction.perform {
            let settings = try self.settings()
            guard settings.solveSessionsData == nil else { return }
            let data = defaults.data(forKey: storageKey) ?? Data("{}".utf8)
            _ = try JSONDecoder().decode([String: SolveSession].self, from: data)
            transaction.track(settings)
            settings.solveSessionsData = data
        }
        // Оставляем исходную копию; после переноса она больше не читается.
    }

    func load(for key: SolveGroupKey) throws -> SolveSession? {
        try allSessions()[key.stringValue]
    }

    func save(_ session: SolveSession, for key: SolveGroupKey) throws {
        var dict = try allSessions()
        dict[key.stringValue] = session
        try persist(dict)
    }

    func clear(for key: SolveGroupKey) throws {
        var dict = try allSessions()
        dict.removeValue(forKey: key.stringValue)
        try persist(dict)
    }

    func clearAll() throws { try persist([:]) }

    func allSessionKeys() throws -> Set<SolveGroupKey> {
        Set(try allSessions().keys.compactMap(SolveGroupKey.init(stringValue:)))
    }

    private func settings() throws -> UserSettings {
        guard let transaction else { throw PersistenceError.staleSession }
        let descriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { $0.id == "singleton" })
        if let settings = try transaction.context.fetch(descriptor).first { return settings }
        let settings = UserSettings()
        transaction.context.insert(settings)
        return settings
    }

    private func allSessions() throws -> [String: SolveSession] {
        let data: Data?
        if transaction != nil {
            data = try settings().solveSessionsData
        } else {
            data = defaults.data(forKey: storageKey)
        }
        guard let data else { return [:] }
        return try JSONDecoder().decode([String: SolveSession].self, from: data)
    }

    private func persist(_ dict: [String: SolveSession]) throws {
        let data = try JSONEncoder().encode(dict)
        if let transaction {
            try transaction.perform {
                let settings = try settings()
                transaction.track(settings)
                settings.solveSessionsData = data
            }
        } else {
            defaults.set(data, forKey: storageKey)
        }
    }
}
