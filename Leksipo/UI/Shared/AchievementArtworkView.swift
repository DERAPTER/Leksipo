import SwiftUI

/// Одна иллюстрация во всех представлениях награды. Название и статус
/// озвучиваются соседним текстом, поэтому декоративное изображение скрыто от VoiceOver.
struct AchievementArtworkView: View {
    let achievement: Achievement
    var isUnlocked = true
    let size: CGFloat

    var body: some View {
        Group {
            if let artwork = achievement.artwork {
                Image(decorative: artwork.rawValue)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .saturation(isUnlocked ? 1 : 0.2)
                    .opacity(isUnlocked ? 1 : 0.55)
            } else {
                Image(systemName: achievement.icon)
                    .font(.system(size: size * 0.48))
                    .foregroundStyle(Color.accent)
                    .frame(width: size, height: size)
                    .background(Color.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.25))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
