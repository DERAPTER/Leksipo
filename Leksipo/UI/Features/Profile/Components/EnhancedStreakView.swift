//
//  EnhancedStreakView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct EnhancedStreakView: View {
    let streak: Int
    let todayGoalCompleted: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(flameColor.opacity(0.1))
                    .frame(width: 70, height: 70)
                Image(systemName: "flame.fill")
                    .font(.system(size: 35))
                    .foregroundColor(flameColor)
            }
            
            VStack(spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(flameColor)
                Text("days_in_row".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var flameColor: Color {
        if streak == 0 {
            return .gray
        } else if todayGoalCompleted {
            return .orange
        } else {
            return .gray.opacity(0.5)
        }
    }
}
