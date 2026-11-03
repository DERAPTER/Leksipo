//
//  SwipeableCardView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SwipeableCardView: View {
    @Bindable var card: Card
    let percentageOfMove: Double
    let isReversed: Bool
    let onToggleFavourite: () -> Void
    
    @State private var isFlipped = false
    
    private let cardWidth: CGFloat = 320
    private let cardHeight: CGFloat = 480
    
    private var frontWord: String { isReversed ? card.translatedWord : card.originWord }
    private var frontDesc: String { isReversed ? card.translatedDescription : card.originDescription }
    private var frontLang: AppLanguage { isReversed ? .russian : .english }
        
    private var backWord: String { isReversed ? card.originWord : card.translatedWord }
    private var backDesc: String { isReversed ? card.originDescription : card.translatedDescription }
    private var backLang: AppLanguage { isReversed ? .english : .russian }
    
    var body: some View {
        ZStack {
            frontSide
                .opacity(isFlipped ? 0 : 1)
            backSide
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .frame(width: cardWidth, height: cardHeight)
        .overlay(strokeOverlay)
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: card.id) { _, _ in
            isFlipped = false
            PronunciationService.shared.stop()
        }
        .onChange(of: isReversed) { _, _ in
            isFlipped = false
        }
        .onDisappear {
            PronunciationService.shared.stop()
        }
    }
    
    // MARK: - Front
    
    private var frontSide: some View {
        cardBase(
            speechText: frontWord,
            speechLanguage: frontLang
        ) {
            VStack(spacing: 0) {
                swipeHintView
                
                Spacer()
                
                VStack(spacing: 12) {
                    cardWord(frontWord)
                    cardDescription(frontDesc)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Back
    
    private var backSide: some View {
        cardBase(
            speechText: backWord,
            speechLanguage: backLang
        ) {
            VStack(spacing: 0) {
                swipeHintView
                
                Spacer()
                
                VStack(spacing: 12) {
                    cardWord(backWord)
                    cardDescription(backDesc)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Building blocks
    
    private func cardBase<Content: View>(
        speechText: String,
        speechLanguage: AppLanguage,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.cardBackground)
                .shadow(color: .shadowColor, radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.stroke, lineWidth: 1)
                )
            
            content()
            
            VStack {
                HStack {
                    speakButton(text: speechText, language: speechLanguage)
                    Spacer()
                    favouriteButton
                }
                Spacer()
            }
        }
    }
    
    private func speakButton(text: String, language: AppLanguage) -> some View {
        Button {
            HapticService.shared.lightImpact()
            PronunciationService.shared.speak(text, language: language)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .foregroundColor(.textSecondary)
                .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("speak".localized())
    }
    
    private var favouriteButton: some View {
        Button(action: onToggleFavourite) {
            Image(systemName: card.isFavourite ? "star.fill" : "star")
                .font(.title2)
                .foregroundColor(card.isFavourite ? .accent : .textSecondary)
                .padding(16)
        }
        .buttonStyle(.plain)
    }
    
    private var swipeHintView: some View {
        ZStack {
            if percentageOfMove > 0 {
                hintText("already_know".localized(), color: .correct, opacity: percentageOfMove)
            }
            if percentageOfMove < 0 {
                hintText("still_learning".localized(), color: .wrong, opacity: -percentageOfMove)
            }
        }
        .frame(height: 50)
    }
    
    private func hintText(_ text: String, color: Color, opacity: Double) -> some View {
        Text(text)
            .font(.title2.bold())
            .foregroundColor(color)
            .padding(8)
            .background(Color.cardBackground.opacity(0.9))
            .cornerRadius(12)
            .opacity(opacity)
    }
    
    private func cardWord(_ text: String) -> some View {
        Text(text)
            .font(.largeTitleCustom)
            .foregroundColor(.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 20)
            .frame(maxWidth: 280)
            .opacity(cardTextOpacity)
    }
    
    @ViewBuilder
    private func cardDescription(_ text: String) -> some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            Text(trimmed)
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 24)
                .opacity(cardTextOpacity * 0.9)
        }
    }
    
    private var cardTextOpacity: Double {
        let fade = max(abs(percentageOfMove), 0)
        return max(1 - fade, 0)
    }
    
    private var strokeOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.correct, lineWidth: 4)
                .opacity(percentageOfMove > 0 ? percentageOfMove : 0)
            
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.wrong, lineWidth: 4)
                .opacity(percentageOfMove < 0 ? -percentageOfMove : 0)
        }
    }
}
