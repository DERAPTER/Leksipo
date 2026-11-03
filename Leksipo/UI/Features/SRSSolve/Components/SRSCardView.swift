//
//  SRSCardView.swift
//  Leksipo
//
//  Created by Егор Халиков on 04.10.2026.
//

import SwiftUI

/// Карточка для SRS-режима.
/// Отличается от `SwipeableCardView`:
/// - Нет свайпов.
/// - Тап переворачивает карточку.
/// - На лицевой стороне — только слово и подсказка.
/// - На обороте — слово + перевод.
struct SRSCardView: View {
    @Bindable var card: Card
    @Binding var isFlipped: Bool
    let isReversed: Bool
    let onToggleFavourite: () -> Void
    
    @State private var speechError: String?

    private let cardWidth: CGFloat = 320
    private let cardHeight: CGFloat = 480
    
    private var frontWord: String { isReversed ? card.translatedWord : card.originWord }
    private var frontDesc: String { isReversed ? card.translatedDescription : card.originDescription }
    private var frontLang: StudyLanguage { isReversed ? card.languagePair.translation : card.languagePair.learning }
        
    private var backWordSmall: String { isReversed ? card.translatedWord : card.originWord }
    private var backWordLarge: String { isReversed ? card.originWord : card.translatedWord }
    private var backDesc: String { isReversed ? card.originDescription : card.translatedDescription }
    private var backLang: StudyLanguage { isReversed ? card.languagePair.learning : card.languagePair.translation }
    
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
        .onTapGesture {
            HapticService.shared.lightImpact()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: card.id) { _, _ in
            isFlipped = false
            PronunciationService.shared.stop()
        }
        .onChange(of: isReversed) { _, _ in
            PronunciationService.shared.stop()
            isFlipped = false
        }
        .alert("error_title".localized(), isPresented: Binding(
            get: { speechError != nil }, set: { if !$0 { speechError = nil } }
        )) { Button("ok".localized()) { speechError = nil } }
        message: { Text(speechError ?? "") }
        .onDisappear {
            PronunciationService.shared.stop()
        }
    }
    
    // MARK: - Sides
    
    private var frontSide: some View {
        cardBase(
            speechText: frontWord,
            speechLanguage: frontLang
        ) {
            VStack(spacing: 0) {
                Text("srs_tap_to_reveal".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 6)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text(frontWord)
                        .font(.largeTitleCustom)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: 280)
                    
                    if !frontDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(frontDesc)
                            .font(.bodyCustom)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: 280)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var backSide: some View {
        cardBase(
            speechText: backWordLarge,
            speechLanguage: backLang
        ) {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text(backWordSmall)
                        .font(.title2)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 20)
                    
                    Divider()
                        .background(Color.stroke)
                        .padding(.horizontal, 40)
                    
                    Text(backWordLarge)
                        .font(.largeTitleCustom)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: 280)
                    
                    if !backDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(backDesc)
                            .font(.bodyCustom)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: 280)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Base
    
    private func cardBase<Content: View>(
        speechText: String,
        speechLanguage: StudyLanguage,
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
    
    private func speakButton(text: String, language: StudyLanguage) -> some View {
        Button {
            HapticService.shared.lightImpact()
            do { try PronunciationService.shared.speak(text, language: language) }
            catch { speechError = error.localizedDescription }
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
}
