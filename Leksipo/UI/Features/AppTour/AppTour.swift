import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppTour {
    enum Step: String {
        case introduction, createGroup, addCard, practiceTab, choosePractice, flipCard, answerCard
        case reviewsTab, reviews, reviewFlip, reviewRate, reviewResult, profileTab, profile, finish

        var message: String { "tour_step_\(rawValue)".localized() }
    }

    let model: ModelContainer
    let sandbox: AppContainer
    private let suiteName: String
    private(set) var step: Step
    private(set) var screen: AppScreen = .cardsGroups
    private(set) var groupID: UUID?
    private(set) var exitRequested = false
    private var didSaveGroup = false

    init(introduce: Bool) throws {
        step = introduce ? .introduction : .createGroup
        let model = try ModelContainer(for: Card.self, CardGroup.self, DailyStat.self, UserSettings.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let suiteName = "Leksipo.AppTour.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else { throw CocoaError(.fileWriteUnknown) }
        self.model = model
        self.suiteName = suiteName
        do {
            sandbox = try AppContainer.live(container: model, defaults: defaults, integrateSystemServices: false)
        } catch {
            defaults.removePersistentDomain(forName: suiteName)
            throw error
        }
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    var nextTab: AppScreen? {
        switch step {
        case .practiceTab: return .solveCards
        case .reviewsTab: return .srsReview
        case .profileTab: return .profile
        default: return nil
        }
    }

    func selectTab(_ screen: AppScreen) {
        guard screen == nextTab else { return }
        self.screen = screen
        switch screen {
        case .solveCards: step = .choosePractice
        case .srsReview: step = .reviews
        case .profile: step = .profile
        case .cardsGroups: break
        }
    }

    func advance(from expected: Step, to next: Step) {
        guard step == expected else { return }
        step = next
    }

    func createdGroup(_ id: UUID) {
        guard step == .createGroup else { return }
        groupID = id
        step = .addCard
    }

    func beginPractice(_ key: SolveGroupKey) {
        guard let groupID, key == .user(groupID) else { return }
        advance(from: .choosePractice, to: .flipCard)
    }

    func leavePractice() {
        if step == .flipCard || step == .answerCard {
            step = .choosePractice
        }
    }

    func reviewCardChanged(isFlipped: Bool) {
        if isFlipped {
            advance(from: .reviewFlip, to: .reviewRate)
        } else {
            advance(from: .reviewRate, to: .reviewFlip)
        }
    }

    func completedReview() {
        if step == .reviewFlip || step == .reviewRate {
            step = .reviewResult
        }
    }

    func leaveReview() {
        switch step {
        case .reviewFlip, .reviewRate: step = .reviews
        case .reviewResult: step = .profileTab
        default: break
        }
    }

    func requestExit() { exitRequested = true }

    func saveGroup(to destination: AppContainer) throws {
        guard !didSaveGroup else { return }
        guard step == .finish, let groupID,
              let group = try sandbox.groupRepository.fetch(id: groupID),
              let snapshot = SharedGroupDocument(group: group).groups.first,
              !snapshot.cards.isEmpty else {
            throw CocoaError(.fileNoSuchFile)
        }
        var name = snapshot.name
        var suffix = 2
        while try destination.groupRepository.nameExists(name, excluding: nil) {
            name = "\(snapshot.name) (\(suffix))"
            suffix += 1
        }

        // The normal importer reuses matching cards and only copies their content.
        let importer = ImportDataViewModel(cardRepository: destination.cardRepository,
                                           groupRepository: destination.groupRepository,
                                           transaction: destination.transaction,
                                           achievementsService: destination.achievementsService,
                                           onComplete: {})
        _ = try importer.importPreparedGroups([
            ImportGroupDTO(name: name, cards: snapshot.cards,
                           learningLanguageCode: snapshot.learningLanguageCode,
                           translationLanguageCode: snapshot.translationLanguageCode)
        ])
        didSaveGroup = true
    }
}

private struct AppTourKey: EnvironmentKey {
    static let defaultValue: AppTour? = nil
}

extension EnvironmentValues {
    var appTour: AppTour? {
        get { self[AppTourKey.self] }
        set { self[AppTourKey.self] = newValue }
    }
}

extension View {
    func tourHighlight(_ isHighlighted: Bool, cornerRadius: CGFloat = 16) -> some View {
        overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.accent, lineWidth: 3)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}
