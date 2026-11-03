import Foundation

@MainActor
@Observable
final class AddFirstCardViewModel {
    private let cards: CardRepository
    private let transaction: PersistenceTransaction
    private let achievements: AchievementsService
    private(set) var errorMessage: String?

    init(cards: CardRepository, transaction: PersistenceTransaction, achievements: AchievementsService) {
        self.cards = cards
        self.transaction = transaction
        self.achievements = achievements
    }

    func save(origin: String, translated: String, originDescription: String, translatedDescription: String,
              group: CardGroup?, isFavourite: Bool) -> Bool {
        errorMessage = nil
        let origin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let translated = translated.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !origin.isEmpty, !translated.isEmpty else { return false }
        do {
            guard try !cards.exists(origin: origin, translated: translated, excluding: nil) else {
                errorMessage = "duplicate_card_message".localized()
                return false
            }
            try transaction.perform {
                let card = try cards.create(origin: origin, translated: translated,
                                            originDescription: originDescription, translatedDescription: translatedDescription,
                                            groups: group.map { [$0] } ?? [])
                if isFavourite { try cards.toggleFavourite(card) }
            }
            achievements.evaluate()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
