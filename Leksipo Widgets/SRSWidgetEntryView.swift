//
//  SRSWidgetEntryView.swift
//  Leksipo Widgets
//
//  Created by Егор Халиков on 20.10.2026.
//

import WidgetKit
import SwiftUI
import UIKit

struct SRSWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: SRSWidgetEntry

    // WidgetKit ограничивает размер исходного растра, независимо от frame.
    // Этих миниатюр хватает для среднего виджета при масштабе экрана 3x.
    private static let idleMascot = UIImage(named: "dachshund-idle")?
        .preparingThumbnail(of: CGSize(width: 240, height: 300))
    private static let restingMascot = UIImage(named: "dachshund-rest")?
        .preparingThumbnail(of: CGSize(width: 240, height: 300))

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
        guard renderingMode == .fullColor else { return .primary }
        return hasDue ? colors.accent : .orange
    }

    private var primaryTextColor: Color {
        renderingMode == .fullColor ? colors.textPrimary : .primary
    }

    private var secondaryTextColor: Color {
        renderingMode == .fullColor ? colors.textSecondary : .primary.opacity(0.8)
    }

    private var iconName: String {
        hasDue ? "arrow.clockwise" : "flame.fill"
    }

    private var number: Int {
        hasDue ? entry.snapshot.dueToday : entry.snapshot.srsStreak
    }

    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Только фон контейнера система может убрать при выборе Clear/Tinted.
        .containerBackground(for: .widget) { colors.background }
        .widgetURL(URL(string: "leksipo://srs"))
    }

    private func localized(_ key: String) -> String {
        SRSWidgetText.string(key)
    }

    private var unavailableView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(renderingMode == .fullColor ? colors.accent : .primary)
                .widgetAccentable()
            Text(localized(statusTitle))
                .font(.headline)
                .foregroundStyle(primaryTextColor)
            Text(localized("widget_open_to_refresh"))
                .font(.caption)
                .foregroundStyle(secondaryTextColor)

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
                mascot
                    .frame(width: 60, height: 64)

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
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(localized(hasDue ? "widget_lets_review" : "widget_keep_it_up"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                Image(systemName: hasDue ? "arrow.up.right" : "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(stateColor)
                    .frame(width: 28, height: 28)
                    .background(stateColor.opacity(0.15), in: Circle())
                    .widgetAccentable()
            }
        }
    }

    // MARK: - Mascot

    private var mascot: some View {
        let thumbnail = hasDue ? Self.idleMascot : Self.restingMascot
        let image = thumbnail.map { Image(uiImage: $0) } ?? Image(systemName: iconName)
        return image
            .renderingMode(.original)
            .resizable()
            .widgetAccentedRenderingMode(.accentedDesaturated)
            .scaledToFit()
            .foregroundStyle(stateColor)
            .accessibilityHidden(true)
    }

    // MARK: - Medium Widget

    private var mediumView: some View {
        HStack(spacing: 12) {
            mascot
                .frame(width: 80, height: 100)

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text(localized(hasDue ? "widget_time_to_review" : "widget_review_streak"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(secondaryTextColor)
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
                .widgetAccentable()
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
