import Foundation
import WidgetKit

@MainActor
@Observable
final class SRSIntegrationService {
    let notifications: NotificationService
    private let cards: CardRepository
    private let stats: StatsRepository
    private let defaults: UserDefaults
    private let store: SRSWidgetStore
    private let now: () -> Date
    private let calendar: Calendar
    private let reloadWidgets: () -> Void
    private let language: () -> String
    private let theme: () -> String
    private let localize: (String) -> String
    private var lastSnapshot: SRSWidgetSnapshot?
    private var lastPlan: [SRSReminder]?
    private(set) var errorMessage: String?

    var remindersEnabled: Bool { defaults.bool(forKey: "srsRemindersEnabled") }
    var reminderHour: Int { min(23, max(0, defaults.object(forKey: "srsReminderHour") as? Int ?? 20)) }
    var reminderMinute: Int { min(59, max(0, defaults.integer(forKey: "srsReminderMinute"))) }

    init(cards: CardRepository, stats: StatsRepository, defaults: UserDefaults,
         store: SRSWidgetStore, notifications: NotificationService,
         now: @escaping () -> Date = { .now }, calendar: Calendar = StudyDay.calendar,
         reloadWidgets: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() },
         language: @escaping () -> String = { LanguageManager.shared.currentLanguage.rawValue },
         theme: @escaping () -> String = { ThemeManager.shared.currentTheme.rawValue },
         localize: @escaping (String) -> String = { $0.localized() }) {
        self.cards = cards
        self.stats = stats
        self.defaults = defaults
        self.store = store
        self.notifications = notifications
        self.now = now
        self.calendar = calendar
        self.reloadWidgets = reloadWidgets
        self.language = language
        self.theme = theme
        self.localize = localize
    }

    func setRemindersEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: "srsRemindersEnabled")
        refresh(force: true)
    }

    func setReminderTime(hour: Int, minute: Int) {
        defaults.set(min(23, max(0, hour)), forKey: "srsReminderHour")
        defaults.set(min(59, max(0, minute)), forKey: "srsReminderMinute")
        refresh(force: true)
    }

    func refresh(force: Bool = false) {
        do {
            let date = now()
            let rawLimit = defaults.integer(forKey: "srsNewCardsPerDay")
            let snapshot = try SRSWidgetSnapshotWriter.make(cardRepository: cards, statsRepository: stats,
                                                            newCardsLimit: rawLimit > 0 ? rawLimit : 20,
                                                            date: date, calendar: calendar)
            var widgetError: String?
            do {
                try store.saveAppearance(theme: theme(), language: language())
                let sameContent = lastSnapshot.map {
                    $0.dueToday == snapshot.dueToday && $0.srsStreak == snapshot.srsStreak &&
                    $0.nextReviewDate == snapshot.nextReviewDate && $0.nextReviewCount == snapshot.nextReviewCount &&
                    $0.timeZoneID == snapshot.timeZoneID && $0.isCurrent(at: date, calendar: calendar)
                } ?? false
                if force || !sameContent || errorMessage != nil {
                    try store.save(snapshot)
                    lastSnapshot = snapshot
                    reloadWidgets()
                }
            } catch {
                store.markUnavailable()
                reloadWidgets()
                widgetError = error.localizedDescription
            }
            let first = snapshot.dueToday > 0 ? date : snapshot.nextReviewDate
            let plan = remindersEnabled ? SRSReminderPlan.make(
                firstDueDay: first, now: date, hour: reminderHour, minute: reminderMinute,
                title: localize("notification_srs_title"), body: localize("notification_srs_body"), calendar: calendar
            ) : []
            if force || lastPlan != plan || notifications.errorMessage != nil {
                lastPlan = plan
                notifications.replace(with: plan)
            }
            errorMessage = widgetError
        } catch {
            // Снимок с последними достоверными числами не перезаписывается нулями.
            store.markUnavailable()
            reloadWidgets()
            errorMessage = error.localizedDescription
            if !remindersEnabled {
                lastPlan = []
                notifications.replace(with: [])
            }
        }
    }
}
