//
//  AnswerCounterView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

/// Счётчик правильных/неправильных ответов, показываемый над карточкой.
struct AnswerCounterView: View {
    let correctCount: Int
    let wrongCount: Int
    let percentageOfMove: Double
    
    var body: some View {
        HStack {
            wrongCounter
            Spacer()
            correctCounter
        }
        .padding(.horizontal)
    }
    
    private var wrongCounter: some View {
        counter(
            count: wrongCount,
            color: .wrong,
            alignmentOffset: -45,
            textOffset: 5,
            highlightOpacity: wrongHighlightOpacity
        )
    }
    
    private var correctCounter: some View {
        counter(
            count: correctCount,
            color: .correct,
            alignmentOffset: 45,
            textOffset: -5,
            highlightOpacity: correctHighlightOpacity
        )
    }
    
    private func counter(
        count: Int,
        color: Color,
        alignmentOffset: CGFloat,
        textOffset: CGFloat,
        highlightOpacity: Double
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .frame(width: 90, height: 60)
                .foregroundColor(.cardBackground)
                .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(color, lineWidth: 2)
                )
            
            Text("\(count)")
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .offset(x: textOffset)
            
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 90, height: 60)
                    .foregroundColor(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(color, lineWidth: 2)
                    )
                Text("+1")
                    .font(.titleCustom)
                    .foregroundColor(.white)
                    .offset(x: textOffset)
            }
            .opacity(highlightOpacity)
            .animation(.easeInOut(duration: 0.2), value: highlightOpacity)
        }
        .offset(x: alignmentOffset)
    }
    
    private var correctHighlightOpacity: Double {
        guard percentageOfMove > 0 else { return 0 }
        return min(percentageOfMove * 1.5, 1.0)
    }
    
    private var wrongHighlightOpacity: Double {
        guard percentageOfMove < 0 else { return 0 }
        return min(-percentageOfMove * 1.5, 1.0)
    }
}
