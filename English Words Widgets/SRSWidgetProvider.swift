import WidgetKit
import SwiftUI

struct SRSWidgetEntry: TimelineEntry {
    let date: Date
    let state: SRSWidgetState
    var snapshot: SRSWidgetSnapshot { state.snapshot ?? .empty }

    init(date: Date, state: SRSWidgetState) { self.date = date; self.state = state }
    init(date: Date, snapshot: SRSWidgetSnapshot) {
        self.date = date
        self.state = snapshot.isCurrent(at: date) ? .current(snapshot) : .stale(snapshot)
    }
}

struct SRSWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SRSWidgetEntry {
        SRSWidgetEntry(date: .now, state: .missing)
    }

    func getSnapshot(in context: Context, completion: @escaping (SRSWidgetEntry) -> Void) {
        completion(SRSWidgetEntry(date: .now, state: SRSWidgetStore.live.read(at: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SRSWidgetEntry>) -> Void) {
        let now = Date.now
        let state = SRSWidgetStore.live.read(at: now)
        var entries = [SRSWidgetEntry(date: now, state: state)]
        let nextHour = now.addingTimeInterval(3600)
        var refresh = nextHour
        if case .current(let snapshot) = state {
            let midnight = Calendar.current.dateInterval(of: .day, for: now)?.end ?? nextHour
            let expiry = min(snapshot.validUntil ?? snapshot.updatedAt.addingTimeInterval(6 * 3600), midnight)
            if expiry > now {
                entries.append(SRSWidgetEntry(date: expiry, state: .stale(snapshot)))
                refresh = min(refresh, expiry)
            }
        }
        // Заранее добавленная stale-entry не зависит от своевременного запуска provider.
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}
