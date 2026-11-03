//
//  CardInListView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct CardInListView: View {
    let card: Card
    let onToggleFavourite: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.originWord)
                    .font(.bodyCustom)
                    .foregroundColor(.textPrimary)
                Text(card.translatedWord)
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: onToggleFavourite) {
                Image(systemName: card.isFavourite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(card.isFavourite ? .accent : .textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 1)
    }
}
