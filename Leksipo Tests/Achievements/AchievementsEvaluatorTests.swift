//
//  AchievementsEvaluatorTests.swift
//  Leksipo Tests
//
//  Created by Егор Халиков on 05.10.2026.
//

import Testing
import Foundation
@testable import English_Words

@Suite("AchievementsEvaluator — чистая логика проверки достижений")
struct AchievementsEvaluatorTests {
    
    /// Удобный фабричный метод — не заполнять все поля каждый раз.
    private func snapshot(
        cardsCreated: Int = 0,
        cardsSolved: Int = 0,
        streak: Int = 0,
        daysGoalCompleted: Int = 0,
        favouritesCount: Int = 0,
        userGroupsCount: Int = 0
    ) -> AchievementsSnapshot {
        AchievementsSnapshot(
            cardsCreated: cardsCreated,
            cardsSolved: cardsSolved,
            streak: streak,
            daysGoalCompleted: daysGoalCompleted,
            favouritesCount: favouritesCount,
            userGroupsCount: userGroupsCount
        )
    }
    
    // MARK: - Пустые состояния
    
    @Test("Пустой снимок и ничего не разблокировано → пусто")
    func emptySnapshotAndNothingUnlocked() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(),
            alreadyUnlocked: []
        )
        #expect(result.isEmpty)
    }
    
    @Test("Пустой снимок, но что-то уже разблокировано → тоже пусто")
    func emptySnapshotWithUnlocked() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(),
            alreadyUnlocked: ["cards_10", "streak_3"]
        )
        #expect(result.isEmpty)
    }
    
    // MARK: - По одному типу
    
    @Test("cardsCreated=10 разблокирует ровно cards_10")
    func cardsCreatedUnlocksOne() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 10),
            alreadyUnlocked: []
        )
        #expect(result.map(\.id) == ["cards_10"])
    }
    
    @Test("cardsCreated=10 разблокирует и cards_10, и не только")
    func cardsCreatedDoesNotTriggerOthers() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 10),
            alreadyUnlocked: []
        )
        #expect(!result.contains(where: { $0.type != .cardsCreated }))
    }
    
    @Test("cardsSolved=50 разблокирует 10 и 50 разом")
    func cardsSolvedUnlocksMultiple() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsSolved: 50),
            alreadyUnlocked: []
        )
        let ids = Set(result.map(\.id))
        #expect(ids == ["solved_10", "solved_50"])
    }
    
    @Test("streak=7 → streak_3 и streak_7")
    func streakUnlocksMultiple() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(streak: 7),
            alreadyUnlocked: []
        )
        let ids = Set(result.map(\.id))
        #expect(ids == ["streak_3", "streak_7"])
    }
    
    @Test("daysGoalCompleted=1 → goal_1")
    func goalCompletedUnlocksFirst() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(daysGoalCompleted: 1),
            alreadyUnlocked: []
        )
        #expect(result.map(\.id) == ["goal_1"])
    }
    
    @Test("favouritesCount=5 → fav_1 и fav_5")
    func favouritesUnlocksMultiple() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(favouritesCount: 5),
            alreadyUnlocked: []
        )
        let ids = Set(result.map(\.id))
        #expect(ids == ["fav_1", "fav_5"])
    }
    
    @Test("userGroupsCount=1 → group_1")
    func groupsUnlocksFirst() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(userGroupsCount: 1),
            alreadyUnlocked: []
        )
        #expect(result.map(\.id) == ["group_1"])
    }
    
    // MARK: - Фильтрация уже разблокированных
    
    @Test("Не возвращает уже разблокированное, даже если условие выполнено")
    func filtersAlreadyUnlocked() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 10, cardsSolved: 10),
            alreadyUnlocked: ["cards_10"]
        )
        #expect(!result.contains(where: { $0.id == "cards_10" }))
        #expect(result.contains(where: { $0.id == "solved_10" }))
    }
    
    @Test("Всё уже разблокировано → пусто")
    func allUnlocked() {
        let allIDs = Set(AchievementsCatalog.all.map(\.id))
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(
                cardsCreated: 1000,
                cardsSolved: 1000,
                streak: 100,
                daysGoalCompleted: 100,
                favouritesCount: 25,
                userGroupsCount: 10
            ),
            alreadyUnlocked: allIDs
        )
        #expect(result.isEmpty)
    }
    
    // MARK: - Границы значений
    
    @Test("Ровно на пороге — разблокируется")
    func exactlyAtThreshold() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 10),
            alreadyUnlocked: []
        )
        #expect(result.contains(where: { $0.id == "cards_10" }))
    }
    
    @Test("На единицу ниже порога — НЕ разблокируется")
    func oneBelowThreshold() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 9),
            alreadyUnlocked: []
        )
        #expect(result.isEmpty)
    }
    
    @Test("За пределами максимума — все верхние достижения разблокированы")
    func wayAboveMaximum() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(
                cardsCreated: 99999,
                cardsSolved: 99999,
                streak: 99999,
                daysGoalCompleted: 99999,
                favouritesCount: 99999,
                userGroupsCount: 99999
            ),
            alreadyUnlocked: []
        )
        #expect(result.count == AchievementsCatalog.all.count)
    }
    
    // MARK: - Мульти-категория
    
    @Test("Одновременно по одному достижению в каждой категории")
    func oneFromEachCategory() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(
                cardsCreated: 10,
                cardsSolved: 10,
                streak: 3,
                daysGoalCompleted: 1,
                favouritesCount: 1,
                userGroupsCount: 1
            ),
            alreadyUnlocked: []
        )
        let ids = Set(result.map(\.id))
        #expect(ids == ["cards_10", "solved_10", "streak_3", "goal_1", "fav_1", "group_1"])
    }
    
    @Test("Порядок возврата соответствует каталогу (не проверяем hash, но проверяем стабильность)")
    func orderMatchesCatalog() {
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 100, streak: 30),
            alreadyUnlocked: []
        )
        let expectedOrder = AchievementsCatalog.all
            .map(\.id)
            .filter { result.map(\.id).contains($0) }
        #expect(result.map(\.id) == expectedOrder)
    }
    
    // MARK: - Проверка связи с каталогом
    
    @Test("Каждое возвращённое достижение реально существует в каталоге")
    func returnedAchievementsExistInCatalog() {
        let catalogIDs = Set(AchievementsCatalog.all.map(\.id))
        let result = AchievementsEvaluator.newlyUnlocked(
            snapshot: snapshot(cardsCreated: 1000, streak: 100),
            alreadyUnlocked: []
        )
        for achievement in result {
            #expect(catalogIDs.contains(achievement.id))
        }
    }
    
    @Test("Каталог содержит как минимум 30 достижений")
    func catalogHasEnoughAchievements() {
        #expect(AchievementsCatalog.all.count >= 30)
    }
    
    @Test("Все id в каталоге уникальны")
    func catalogIDsAreUnique() {
        let ids = AchievementsCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
