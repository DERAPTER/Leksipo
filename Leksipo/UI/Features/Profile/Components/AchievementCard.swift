//
//  AchievementCard.swift
//  Leksipo
//
//  Created by Егор Халиков on 26.09.2026.
//

import SwiftUI

struct AchievementCard: View {
    let status: AchievementStatus
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: status.achievement.icon)
                .font(.system(size: 40))
                .foregroundColor(status.isUnlocked ? .yellow : .gray.opacity(0.3))
            
            Text(status.achievement.title)
                .font(.bodyCustom.weight(.semibold))
                .foregroundColor(status.isUnlocked ? .textPrimary : .textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(status.achievement.description)
                .font(.caption2)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            if status.isUnlocked, let date = status.unlockedDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.accent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .opacity(status.isUnlocked ? 1 : 0.6)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(status.isUnlocked ? Color.yellow : Color.stroke,
                        lineWidth: status.isUnlocked ? 2 : 1)
        )
    }
}
