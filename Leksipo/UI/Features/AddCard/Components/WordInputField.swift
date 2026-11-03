//
//  WordInputField.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

// Переиспользуемое поле ввода слова/перевода.

struct WordInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.bodyCustom)
                .foregroundColor(.textPrimary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.stroke, lineWidth: 1)
                )
        }
    }
}
