//
//  EnhancedDailyGoalView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct EnhancedDailyGoalView: View {
    let goal: Int
    let solved: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
                
                Text("\(Int(progress * 100))%")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.accent)
            }
            
            VStack(spacing: 4) {
                Text("\(solved)/\(goal)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("daily_goal".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
