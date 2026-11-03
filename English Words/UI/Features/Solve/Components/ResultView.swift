//
//  ResultView.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct ResultView: View {
    let successCount: Int
    let failCount: Int
    let progressFraction: Double
    let hasMistakes: Bool
    let onRestart: () -> Void
    let onRestartMistakes: (() -> Void)?
    
    private var percentageOfCorrect: Int {
        Int(progressFraction * 100)
    }
    
    var body: some View {
        VStack {
            Spacer(minLength: 40)
            
            VStack(spacing: 16) {
                Text("your_progress".localized())
                    .font(.titleCustom)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                progressCircle
                    .padding(.vertical, 4)
                
                VStack(spacing: 12) {
                    StatRow(
                        title: "know".localized(),
                        value: "\(successCount)",
                        color: .correct
                    )
                    StatRow(
                        title: "still_learning_short".localized(),
                        value: "\(failCount)",
                        color: .wrong
                    )
                }
                .padding(.top, 8)
                
                buttons
            }
            .padding(24)
            .background(Color.cardBackground)
            .cornerRadius(30)
            .shadow(color: .shadowColor, radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            
            Spacer(minLength: 40)
        }
    }
    
    private var progressCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.stroke, lineWidth: 25)
                .frame(width: 180, height: 180)
            
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(Color.accent, style: StrokeStyle(lineWidth: 25, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 180, height: 180)
            
            if percentageOfCorrect == 100 {
                MascotView(pose: .celebrate)
                    .frame(width: 150, height: 150)
            } else {
                Text("\(percentageOfCorrect)%")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
        }
    }
    
    @ViewBuilder
    private var buttons: some View {
        if hasMistakes {
            VStack(spacing: 12) {
                Button {
                    onRestartMistakes?()
                } label: {
                    Text("repeat_mistakes".localized())
                        .font(.bodyCustom.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.accent)
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
                
                Button(action: onRestart) {
                    Text("start_over_button".localized())
                        .font(.bodyCustom.weight(.semibold))
                        .foregroundColor(.accent)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.cardBackground)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.accent, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        } else {
            Button(action: onRestart) {
                Text("start_over_button".localized())
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Color.accent)
                    .cornerRadius(25)
            }
            .buttonStyle(.plain)
        }
    }
}
