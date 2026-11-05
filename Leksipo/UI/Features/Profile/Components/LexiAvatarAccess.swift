import Foundation

protocol LexiAvatarOption: RawRepresentable, Identifiable, Equatable where RawValue == String {
    static var titlePrefix: String { get }
    var unlockRequirement: LexiAvatarUnlockRequirement? { get }
}

extension LexiAvatarOption {
    var id: Self { self }
    // Also stored for previously equipped items, so keep this key stable.
    var optionID: String { "\(Self.titlePrefix)_\(rawValue)" }
    var title: String { optionID.localized() }
}

enum LexiAvatarUnlockRequirement {
    case longTermCards(Int)
    case reviewStreak(Int)
    case cardsCreated(Int)
    case correctAnswers(Int)
    case favourites(Int)

    var achievementID: String {
        switch self {
        case .longTermCards(let count): return "srs_long_term_\(count)"
        case .reviewStreak(let days): return "srs_streak_\(days)"
        case .cardsCreated(let count): return "cards_\(count)"
        case .correctAnswers(let count): return "solved_\(count)"
        case .favourites(let count): return "fav_\(count)"
        }
    }

    var caption: String {
        let key: String
        let value: Int
        switch self {
        case .longTermCards(let count): (key, value) = ("profile_avatar_unlock_long_term", count)
        case .reviewStreak(let days): (key, value) = ("profile_avatar_unlock_streak", days)
        case .cardsCreated(let count): (key, value) = ("profile_avatar_unlock_created", count)
        case .correctAnswers(let count): (key, value) = ("profile_avatar_unlock_answers", count)
        case .favourites(let count): (key, value) = ("profile_avatar_unlock_favourites", count)
        }
        return String(format: key.localized(), value)
    }
}

struct LexiAvatarAccess {
    let unlockedAchievementIDs: Set<String>
    let previouslyEquippedOptionIDs: Set<String>

    func unmetRequirement(for option: some LexiAvatarOption) -> LexiAvatarUnlockRequirement? {
        guard let requirement = option.unlockRequirement,
              !unlockedAchievementIDs.contains(requirement.achievementID),
              !previouslyEquippedOptionIDs.contains(option.optionID) else { return nil }
        return requirement
    }
}
