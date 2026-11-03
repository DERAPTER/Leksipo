import Foundation

struct SRSWidgetSnapshot: Codable, Equatable {
    let dueToday: Int
    let srsStreak: Int
    let nextReviewDate: Date?
    let nextReviewCount: Int
    let updatedAt: Date
    var validUntil: Date? = nil
    var timeZoneID: String? = nil

    static let empty = SRSWidgetSnapshot(dueToday: 0, srsStreak: 0, nextReviewDate: nil, nextReviewCount: 0, updatedAt: .distantPast)

    func isCurrent(at date: Date, calendar: Calendar = .current) -> Bool {
        guard updatedAt <= date, calendar.isDate(updatedAt, inSameDayAs: date),
              timeZoneID.map({ $0 == calendar.timeZone.identifier }) ?? true else { return false }
        let expiry = validUntil ?? updatedAt.addingTimeInterval(6 * 3600)
        return date < expiry
    }
}

enum SRSWidgetState: Equatable {
    case current(SRSWidgetSnapshot)
    case stale(SRSWidgetSnapshot)
    case unavailable(SRSWidgetSnapshot?)
    case missing

    var snapshot: SRSWidgetSnapshot? {
        switch self {
        case .current(let snapshot), .stale(let snapshot): return snapshot
        case .unavailable(let snapshot): return snapshot
        case .missing: return nil
        }
    }
}

/// Формат v1 расширяется optional-полями; прежний снимок остаётся читаемым.
struct SRSWidgetStore {
    static let appGroupID = "group.com.DERAPTER.English-Words"
    static var live: SRSWidgetStore {
        // suiteName сам по себе может создать локальные preferences даже без
        // entitlement. Такой контейнер не обеспечивает обмен с расширением.
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil else {
            return SRSWidgetStore(defaults: nil)
        }
        return SRSWidgetStore(defaults: UserDefaults(suiteName: appGroupID))
    }
    private let defaults: UserDefaults?
    private let key = "srs_widget_snapshot_v1"
    private let errorKey = "srs_widget_snapshot_unavailable"

    init(defaults: UserDefaults?) { self.defaults = defaults }

    func save(_ snapshot: SRSWidgetSnapshot) throws {
        guard let defaults else { throw StoreError.unavailable }
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: key)
        defaults.removeObject(forKey: errorKey)
    }

    func markUnavailable() {
        defaults?.set(true, forKey: errorKey)
    }

    func read(at date: Date, calendar: Calendar = .current) -> SRSWidgetState {
        guard let defaults else { return .unavailable(nil) }
        guard let data = defaults.data(forKey: key) else {
            return defaults.object(forKey: key) != nil || defaults.bool(forKey: errorKey) ? .unavailable(nil) : .missing
        }
        do {
            let snapshot = try JSONDecoder().decode(SRSWidgetSnapshot.self, from: data)
            guard snapshot.dueToday >= 0, snapshot.srsStreak >= 0, snapshot.nextReviewCount >= 0 else { return .unavailable(nil) }
            if defaults.bool(forKey: errorKey) { return .unavailable(snapshot) }
            return snapshot.isCurrent(at: date, calendar: calendar) ? .current(snapshot) : .stale(snapshot)
        } catch { return .unavailable(nil) }
    }

    func saveAppearance(theme: String, language: String) throws {
        guard let defaults else { throw StoreError.unavailable }
        defaults.set(theme, forKey: "widget_current_theme")
        defaults.set(language, forKey: "appLanguage")
    }

    static func saveTheme(_ theme: AppTheme) {
        live.defaults?.set(theme.rawValue, forKey: "widget_current_theme")
    }

    static func loadTheme() -> AppTheme {
        AppTheme(rawValue: live.defaults?.string(forKey: "widget_current_theme") ?? "beige") ?? .beige
    }

    static func loadLanguageCode() -> String {
        let raw = live.defaults?.string(forKey: "appLanguage")
        if raw == "ru" || raw == "en" { return raw ?? "en" }
        return Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "ru" : "en"
    }

    enum StoreError: Error { case unavailable }
}

enum SRSWidgetText {
    static func string(_ key: String, language: String = SRSWidgetStore.loadLanguageCode(), bundle: Bundle = .main) -> String {
        let code = language == "ru" ? "ru" : "en"
        let localized = bundle.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle
        return localized.localizedString(forKey: key, value: nil, table: nil)
    }
}
