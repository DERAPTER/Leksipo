import Testing
@testable import English_Words

@MainActor
struct LexiAvatarAccessTests {
    @Test("В каждой категории есть стартовый выбор и награды из своей линии достижений")
    func catalog() throws {
        let categories: [(options: [any LexiAvatarOption], type: AchievementType)] = [
            (LexiAvatarBackground.allCases, .longTermCards),
            (LexiAvatarHeadwear.allCases, .srsStreak),
            (LexiAvatarHeadphones.allCases, .srsStreak),
            (LexiAvatarNeckwear.allCases, .cardsCreated),
            (LexiAvatarGlasses.allCases, .cardsSolved),
            (LexiAvatarEarAccessory.allCases, .favourites)
        ]
        for category in categories {
            let requirements = category.options.compactMap(\.unlockRequirement)
            #expect(!requirements.isEmpty)
            #expect(category.options.count - requirements.count >= 2)
            for requirement in requirements {
                let achievement = try #require(AchievementsCatalog.achievement(withID: requirement.achievementID))
                #expect(achievement.type == category.type)
                #expect(!achievement.isRetired)
            }
        }
    }

    @Test("Ранее выбранный образ доступен, соседние награды остаются закрытыми")
    func existingOutfit() {
        let original = LexiAvatarAppearance(background: .stars, headwear: .chefHat, neckwear: .scarf,
                                            glasses: .round, earAccessory: .none, headphones: .none)
        let access = LexiAvatarAccess(unlockedAchievementIDs: [], previouslyEquippedOptionIDs: original.gatedOptionIDs)
        #expect(access.unmetRequirement(for: LexiAvatarBackground.stars) == nil)
        #expect(access.unmetRequirement(for: LexiAvatarHeadwear.chefHat) == nil)
        #expect(access.unmetRequirement(for: LexiAvatarHeadwear.ushanka) != nil)
        #expect(access.unmetRequirement(for: LexiAvatarHeadwear.none) == nil)
    }
}
