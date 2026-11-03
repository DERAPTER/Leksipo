//
//  StatCard.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .shadowColor, radius: 5, x: 0, y: 2)
    }
}
