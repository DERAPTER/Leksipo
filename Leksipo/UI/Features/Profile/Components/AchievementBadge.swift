//
//  AchievementBadge.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct AchievementBadge: View {
    let icon: String
    let title: String
    let unlocked: Bool
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(unlocked ? .yellow : .gray.opacity(0.3))
            Text(title)
                .font(.captionCustom)
                .foregroundColor(unlocked ? .textPrimary : .textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(Color.cardBackground.opacity(unlocked ? 1 : 0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(unlocked ? Color.yellow : Color.clear, lineWidth: 1)
        )
        .shadow(color: .shadowColor, radius: 3, x: 0, y: 1)
    }
}
