//
//  AchievementNotificationView.swift
//  Leksipo
//
//  Created by Егор Халиков on 26.09.2026.
//

import SwiftUI

struct AchievementNotificationView: View {
    let achievement: Achievement
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            AchievementArtworkView(achievement: achievement, size: 64)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("achievement_unlocked".localized())
                    .font(.captionCustom)
                    .foregroundColor(.yellow)
                
                Text(achievement.title)
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundColor(.textPrimary)
                
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -200)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}
