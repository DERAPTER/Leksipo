import SwiftUI

struct AllAchievementsSheet: View {
    private enum Category: String, CaseIterable, Identifiable {
        case practice, collection
        var id: String { rawValue }
        var title: String {
            switch self {
            case .practice: return "progress_practice_awards".localized()
            case .collection: return "progress_other_awards".localized()
            }
        }
    }

    let achievements: [AchievementStatus]
    @Environment(\.dismiss) private var dismiss
    @State private var category = Category.practice

    private var visibleAchievements: [AchievementStatus] {
        achievements.filter { status in
            switch category {
            case .practice: return status.achievement.isFeatured && !status.achievement.isRetired
            case .collection: return !status.achievement.isFeatured && !status.achievement.isRetired
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("achievements".localized(), selection: $category) {
                    ForEach(Category.allCases) { item in Text(item.title).tag(item) }
                }
                .pickerStyle(.segmented).padding()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if visibleAchievements.isEmpty {
                            Text("progress_awards_empty".localized()).font(.bodyCustom).foregroundStyle(Color.textSecondary)
                        }
                        ForEach(visibleAchievements) { AchievementCard(status: $0) }
                    }
                    .padding().frame(maxWidth: 760).frame(maxWidth: .infinity)
                }
                .id(category)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("all_achievements".localized()).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("close".localized()) { dismiss() } } }
        }
    }
}
