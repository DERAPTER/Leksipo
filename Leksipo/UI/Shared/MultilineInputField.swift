//
//  MultilineInputField.swift
//  Leksipo
//
//  Created by Егор Халиков on 06.10.2026.
//

import SwiftUI

/// Многострочное поле ввода — для описаний карточек.
///
/// Отличия от `WordInputField`:
/// - высота фиксированная (`minHeight`, по умолчанию 100 pt ≈ 4 строки);
/// - если текст не вмещается — внутри появляется прокрутка;
/// - плейсхолдер показывается, пока поле пустое.
struct MultilineInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.bodyCustom)
                .foregroundColor(.textPrimary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.bodyCustom)
                        .foregroundColor(.textSecondary.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.bodyCustom)
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .frame(minHeight: minHeight)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.stroke, lineWidth: 1)
            )
        }
    }
}
