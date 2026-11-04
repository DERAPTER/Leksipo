import Foundation

/// Стабильные ID наград и биты зафиксированных событий. Уже назначенные биты
/// нельзя переиспользовать: они сохраняются в базе и резервных копиях.
enum SRSMilestone: String, CaseIterable {
    case firstReview = "srs_first_review"
    case firstClear = "srs_first_clear"
    case weekRecall = "srs_week_recall"
    case monthRecall = "srs_month_recall"
    case recovery = "srs_recovery"

    var mask: Int {
        switch self {
        case .firstReview: return 1
        case .firstClear: return 2
        case .weekRecall: return 4
        case .monthRecall: return 8
        case .recovery: return 16
        }
    }

    static var validMask: Int { allCases.reduce(0) { $0 | $1.mask } }

    var artwork: AchievementArtwork {
        switch self {
        case .firstReview: return .firstReview
        case .firstClear: return .allDone
        case .weekRecall: return .weekLater
        case .monthRecall: return .longMemory
        case .recovery: return .wordTamed
        }
    }
}
