//
//  CardStatsSection.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct CardStatsSection: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("card_info".localized())
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)
            
            StatRow(
                title: "creation_date".localized(),
                value: card.dateAdded.formatted(date: .abbreviated, time: .omitted)
            )
            
            Text("answer_statistics".localized())
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)
                .padding(.top, 8)
            
            StatRow(
                title: "correct".localized(),
                value: "\(card.correctCount)",
                color: .correct
            )
            
            StatRow(
                title: "wrong".localized(),
                value: "\(card.wrongCount)",
                color: .wrong
            )
            
            StatRow(
                title: "total_attempts".localized(),
                value: "\(card.totalAttempts)"
            )
            
            if card.totalAttempts > 0 {
                StatRow(
                    title: "success_rate".localized(),
                    value: String(format: "%.1f%%", card.successRate * 100),
                    color: .accent
                )
            }
        }
    }
}
