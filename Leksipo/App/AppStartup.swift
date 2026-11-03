import Foundation
import SwiftData

@MainActor
@Observable
final class AppStartup {
    private(set) var container: ModelContainer?
    private(set) var app: AppContainer?
    private(set) var errorMessage: String?
    private(set) var isStarting = false
    private let makeContainer: @MainActor () throws -> ModelContainer
    private let makeApp: @MainActor (ModelContainer) throws -> AppContainer
    private let migrate: @MainActor (ModelContext) throws -> Void

    init(
        makeContainer: @escaping @MainActor () throws -> ModelContainer = {
            try ModelContainer(for: Card.self, CardGroup.self, DailyStat.self, UserSettings.self)
        },
        migrate: @escaping @MainActor (ModelContext) throws -> Void = { try JSONToSwiftDataMigrator(context: $0).migrateIfNeeded() },
        makeApp: @escaping @MainActor (ModelContainer) throws -> AppContainer = { try AppContainer.live(container: $0) }
    ) {
        self.makeContainer = makeContainer
        self.migrate = migrate
        self.makeApp = makeApp
    }

    func start() {
        guard app == nil, !isStarting else { return }
        isStarting = true
        errorMessage = nil
        defer { isStarting = false }
        do {
            let model = try container ?? makeContainer()
            container = model
            try migrate(model.mainContext)
            app = try makeApp(model)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore(_ data: Data) {
        guard let container, app == nil else { return }
        do {
            try BackupService.restoreBackup(from: data, context: container.mainContext)
            app = try makeApp(container)
            app?.didRestoreData()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
