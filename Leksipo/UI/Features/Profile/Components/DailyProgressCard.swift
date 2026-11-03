//
//  DailyProgressCard.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct DailyProgressCard: View {
    let stats: ProfileViewModel.Stats
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                Text("your_progress_today".localized())
                    .font(.titleCustom)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(alignment: .center, spacing: 20) {
                    EnhancedStreakView(
                        streak: stats.streak,
                        todayGoalCompleted: stats.todayGoalCompleted
                    )
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.stroke)
                        .frame(width: 1, height: 80)
                    
                    Spacer()
                    
                    EnhancedDailyGoalView(
                        goal: stats.dailyGoal,
                        solved: stats.todaySolved,
                        progress: stats.dailyProgress
                    )
                }
                
                progressBar
                
                motivationText
                
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                    Text("tap_to_change_goal".localized())
                        .font(.caption2)
                }
                .foregroundColor(.accent)
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 4)
    }
    
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("goal_progress".localized())
                    .font(.bodyCustom)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(stats.todaySolved)/\(stats.dailyGoal)")
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundColor(.accent)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.stroke.opacity(0.3))
                        .frame(height: 12)
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(Color.accent)
                        .frame(
                            width: geometry.size.width * stats.dailyProgress,
                            height: 12
                        )
                        .cornerRadius(6)
                }
            }
            .frame(height: 12)
        }
    }
    
    @ViewBuilder
    private var motivationText: some View {
        if stats.dailyProgress >= 1 {
            Text("congrats_goal_completed".localized())
                .font(.captionCustom)
                .foregroundColor(.accent)
        } else if stats.dailyProgress >= 0.7 {
            Text("almost_there".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
        } else if stats.dailyProgress >= 0.3 {
            Text("halfway_to_goal".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
        } else {
            Text(String(
                format: "left_to_goal".localized(),
                max(stats.dailyGoal - stats.todaySolved, 0)
            ))
            .font(.captionCustom)
            .foregroundColor(.textSecondary)
        }
    }
}
