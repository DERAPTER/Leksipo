import SwiftUI

struct AchievementCard: View {
    let status: AchievementStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AchievementArtworkView(achievement: status.achievement, isUnlocked: status.isUnlocked,
                                       size: status.achievement.artwork == nil ? 44 : 104)
                VStack(alignment: .leading, spacing: 5) {
                    Text(status.achievement.title).font(.bodyCustom.weight(.semibold)).foregroundStyle(Color.textPrimary)
                    Text(status.achievement.description).font(.captionCustom).foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
                if status.isUnlocked { Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.accent) }
            }
            if status.isUnlocked {
                if let date = status.unlockedDate {
                    Text(date.formatted(.dateTime.day().month().year().locale(LanguageManager.shared.currentLanguage.locale)))
                        .font(.captionCustom).foregroundStyle(Color.textSecondary)
                }
            } else if !status.achievement.isRetired {
                ProgressView(value: status.progress).tint(Color.accent)
                    .accessibilityLabel(status.achievement.title)
                Text("\(status.progressValue) / \(status.achievement.requiredValue)")
                    .font(.captionCustom.weight(.semibold)).foregroundStyle(Color.accent)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }
}
