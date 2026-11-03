import Foundation

/// Язык содержимого карточки, независимо от локализации интерфейса.
struct StudyLanguage: Hashable, Identifiable {
    let code: String
    var id: String { code }

    private init(validatedCode: String) { code = validatedCode }

    init?(code: String) {
        let parts = code.replacingOccurrences(of: "_", with: "-").split(separator: "-", omittingEmptySubsequences: false)
        guard let first = parts.first, Self.baseCodes.contains(first.lowercased()),
              parts.dropFirst().allSatisfy({ (2...8).contains($0.count) && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isLetter) }) else { return nil }
        self.code = ([first.lowercased()] + parts.dropFirst().map {
            $0.count == 4 ? $0.lowercased().capitalized : $0.uppercased()
        }).joined(separator: "-")
    }

    static let english = StudyLanguage(validatedCode: "en")
    static let russian = StudyLanguage(validatedCode: "ru")
    static let baseCodes = Set(Locale.LanguageCode.isoLanguageCodes.map(\.identifier))
    static let all = baseCodes.sorted().map { StudyLanguage(validatedCode: $0) }

    var baseCode: String { String(code.prefix(while: { $0 != "-" })) }

    var displayName: String {
        LanguageManager.shared.currentLanguage.locale.localizedString(forIdentifier: code) ?? code
    }

    var nativeName: String { Locale(identifier: code).localizedString(forIdentifier: code) ?? code }
}

struct StudyLanguagePair: Hashable {
    var learning: StudyLanguage = .english
    var translation: StudyLanguage = .russian

    static let legacy = StudyLanguagePair()
    var displayName: String { "\(learning.displayName) → \(translation.displayName)" }
}

enum StudyLanguageError: LocalizedError {
    case invalidCode
    case incompatibleGroup
    case sharedCards
    case duplicateCard

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "study_language_invalid".localized()
        case .incompatibleGroup: return "study_language_mismatch".localized()
        case .sharedCards: return "study_language_shared_cards".localized()
        case .duplicateCard: return "duplicate_card_message".localized()
        }
    }
}
