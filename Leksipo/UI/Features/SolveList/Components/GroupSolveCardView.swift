//
//  GroupSolveCardView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct GroupSolveCardView: View {
    let item: SolveListViewModel.GroupItem
    
    var body: some View {
        VStack(spacing: 8) {
            Text(item.name)
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            if let pair = item.languagePair {
                Text(pair.displayName).font(.captionCustom)
                    .foregroundStyle(Color.textSecondary).lineLimit(2)
            }
            if item.hasUnfinishedSession {
                continueIndicator
            } else if item.totalCards > 0 {
                Text("\(item.totalCards)")
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            } else {
                Text("empty_group_short".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    item.hasUnfinishedSession ? Color.accent : Color.stroke,
                    lineWidth: item.hasUnfinishedSession ? 2 : 1
                )
        )
    }
    
    private var continueIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.circle.fill")
                .font(.caption)
            Text(String(
                format: "continue_session".localized(),
                item.solvedInSession,
                item.totalCards
            ))
            .font(.captionCustom)
        }
        .foregroundColor(.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accent.opacity(0.15))
        .cornerRadius(12)
    }
}
