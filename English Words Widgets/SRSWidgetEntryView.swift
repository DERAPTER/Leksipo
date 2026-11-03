//
//  SRSWidgetEntryView.swift
//  English Words Widgets
//
//  Created by Егор Халиков on 20.10.2026.
//

import WidgetKit
import SwiftUI

struct SRSWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: SRSWidgetEntry

    private var hasDue: Bool {
        entry.snapshot.dueToday > 0
    }

    // MARK: - Theme & Colors

    private var theme: AppTheme {
        SRSWidgetStore.loadTheme()
    }

    private var colors: ThemeColors {
        ThemeColors.forTheme(theme)
    }

    private var stateColor: Color {
        hasDue ? colors.accent : .orange
    }

    private var iconName: String {
        hasDue ? "arrow.clockwise" : "flame.fill"
    }

    private var number: Int {
        hasDue ? entry.snapshot.dueToday : entry.snapshot.srsStreak
    }

    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            Group {
                if case .current = entry.state {
                switch family {
                case .systemSmall:
                    smallView
                default:
                    mediumView
                }
                } else {
                    unavailableView
                }
            }
            .padding(16)
            .widgetURL(URL(string: "englishwords://srs"))
        }
    }

    private func localized(_ key: String) -> String {
        SRSWidgetText.string(key)
    }

    private var unavailableView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(colors.accent)
            Text(localized(statusTitle))
                .font(.headline)
                .foregroundStyle(colors.textPrimary)
            Text(localized("widget_open_to_refresh"))
                .font(.caption)
                .foregroundStyle(colors.textSecondary)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.locale, Locale(identifier: SRSWidgetStore.loadLanguageCode()))
    }

    private var statusTitle: String {
        switch entry.state {
        case .stale: return "widget_outdated"
        case .unavailable: return "widget_unavailable"
        case .missing: return "widget_not_ready"
        case .current: return "widget_time_to_review"
        }
    }

    private var statusIcon: String {
        switch entry.state {
        case .stale: return "clock.badge.exclamationmark"
        case .unavailable: return "exclamationmark.triangle"
        case .missing: return "arrow.clockwise"
        case .current: return iconName
        }
    }

    // MARK: - Small Widget
    
    private var smallView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(0.15))
                        .frame(width: 46, height: 46)

                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(stateColor)
                }

                Spacer(minLength: 4)

                Text("\(number)")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(stateColor)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .widgetAccentable()
            }

            Spacer(minLength: 8)

            HStack(alignment: .bottom, spacing: 2) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localized(hasDue ? "widget_cards_due" : "widget_day_streak"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(localized(hasDue ? "widget_lets_review" : "widget_keep_it_up"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                Image(systemName: hasDue ? "arrow.up.right" : "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(stateColor)
                    .frame(width: 28, height: 28)
                    .background(stateColor.opacity(0.15), in: Circle())
            }
        }
    }

    // MARK: - Medium Widget

    private var mediumView: some View {
        HStack(spacing: 12) {
            Image(decorative: hasDue ? "dachshund-idle" : "dachshund-rest")
                .renderingMode(.original)
                .resizable()
                .widgetAccentedRenderingMode(.fullColor)
                .scaledToFit()
                .frame(width: 80, height: 100)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text(localized(hasDue ? "widget_time_to_review" : "widget_review_streak"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Image(systemName: hasDue ? "sparkles" : "checkmark.circle.fill")
                    Text(localized(hasDue ? "widget_ready_when_you_are" : "widget_all_caught_up"))
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(stateColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            Text("\(number)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(stateColor)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: 72, alignment: .trailing)
                .widgetAccentable()
        }
    }

    // MARK: - Subtitle

    private var subtitle: String {
        if hasDue {
            return entry.snapshot.dueToday == 1
                ? localized("widget_card_waiting")
                : String(format: localized("widget_cards_waiting"), entry.snapshot.dueToday)
        }

        if entry.snapshot.srsStreak == 0 {
            return localized("widget_start_streak")
        }

        return entry.snapshot.srsStreak == 1
            ? localized("widget_1_day_learning")
            : String(format: localized("widget_days_learning"), entry.snapshot.srsStreak)
    }
}

// MARK: - Previews

#Preview("Small — due", as: .systemSmall) {
    SRSWidget()
} timeline: {
    let now = Date.now
    SRSWidgetEntry(date: now, snapshot: SRSWidgetSnapshot(
        dueToday: 12,
        srsStreak: 5,
        nextReviewDate: nil,
        nextReviewCount: 0,
        updatedAt: now
    ))
}

#Preview("Small — streak", as: .systemSmall) {
    SRSWidget()
} timeline: {
    let now = Date.now
    SRSWidgetEntry(date: now, snapshot: SRSWidgetSnapshot(
        dueToday: 0,
        srsStreak: 7,
        nextReviewDate: nil,
        nextReviewCount: 0,
        updatedAt: now
    ))
}

#Preview("Medium — due", as: .systemMedium) {
    SRSWidget()
} timeline: {
    let now = Date.now
    SRSWidgetEntry(date: now, snapshot: SRSWidgetSnapshot(
        dueToday: 12,
        srsStreak: 5,
        nextReviewDate: nil,
        nextReviewCount: 0,
        updatedAt: now
    ))
}

#Preview("Medium — caught up", as: .systemMedium) {
    SRSWidget()
} timeline: {
    let now = Date.now
    SRSWidgetEntry(date: now, snapshot: SRSWidgetSnapshot(
        dueToday: 0,
        srsStreak: 7,
        nextReviewDate: nil,
        nextReviewCount: 0,
        updatedAt: now
    ))
}
