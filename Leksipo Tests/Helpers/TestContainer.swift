//
//  TestContainer.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Foundation
import SwiftData
@testable import English_Words

/// In-memory контейнер для тестов репозиториев и сервисов.
/// Не трогает диск, полностью изолирован между тестами.
@MainActor
enum TestContainer {
    
    /// Пустой in-memory ModelContainer с боевой схемой.
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Card.self,
            CardGroup.self,
            DailyStat.self,
            UserSettings.self,
            configurations: config
        )
    }
    
    /// Готовый набор репозиториев на in-memory контейнере.
    static func makeRepositories() throws -> Repositories {
        let container = try makeContainer()
        let context = container.mainContext
        
        return Repositories(
            container: container,
            card: SwiftDataCardRepository(context: context),
            group: SwiftDataGroupRepository(context: context),
            stats: SwiftDataStatsRepository(context: context)
        )
    }
    
    struct Repositories {
        let container: ModelContainer
        let card: CardRepository
        let group: GroupRepository
        let stats: StatsRepository
    }
}
