//
//  SRSView.swift
//  English Words
//
//  Created by Егор Халиков on 07.10.2026.
//

import SwiftUI

struct SRSView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TabBarVisibility.self) private var tabBarVisibility
    
    @AppStorage("isReverseCardMode") private var isReverseMode: Bool = false
    
    @State private var viewModel: SRSViewModel
    
    init(container: AppContainer) {
        _viewModel = State(initialValue: SRSViewModel(
            cardRepository: container.cardRepository,
            statsRepository: container.statsRepository,
            sessionCoordinator: container.solveSessionCoordinator,
            achievementsService: container.achievementsService,
            answerRecorder: container.answerRecorder
        ))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            content
                .allowsHitTesting(!viewModel.isProcessingAnswer)
        }
        .navigationTitle("srs_review_title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isReverseMode.toggle()
                    HapticService.shared.lightImpact()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(isReverseMode ? .accent : .textSecondary)
                }
            }
        }
        .alert("error_title".localized(), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ok".localized()) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
        .onAppear {
            tabBarVisibility.isVisible = false
            viewModel.onAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            viewModel.onAppear()
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
            PronunciationService.shared.stop()
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .empty:
            emptyState
            
        case .completed:
            SRSResultView(
                reviewedCount: viewModel.reviewedCount,
                qualityCounts: viewModel.qualityCounts,
                nextReviewDate: viewModel.nextReviewDate,
                nextReviewCount: viewModel.nextReviewCount,
                onFinish: { dismiss() }
            )
            
        case .solving:
            solvingScreen
        }
    }
    
    // MARK: - Empty
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.correct)
            
            Text("srs_overview_all_caught_up".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Solving screen
    
    private var solvingScreen: some View {
        VStack {
            Text("\(viewModel.currentProgress)/\(viewModel.totalProgress)")
                .font(.titleCustom)
                .foregroundColor(.textSecondary)
                .padding(.top, 20)
            
            Spacer()
            
            cardArea
            
            Spacer()
            
            buttonsArea
                .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var cardArea: some View {
        if let card = viewModel.currentCard {
            SRSCardView(
                card: card,
                isFlipped: $viewModel.isCardFlipped,
                isReversed: isReverseMode,
                onToggleFavourite: { viewModel.toggleFavouriteCurrentCard() }
            )
        } else {
            Color.clear.frame(width: 320, height: 480)
        }
    }
    
    @ViewBuilder
    private var buttonsArea: some View {
        if viewModel.isCardFlipped {
            SRSQualityButtonsView(
                intervalPreviews: viewModel.intervalPreviews(),
                onRate: { quality in
                    Task { await viewModel.rateCurrentCard(quality) }
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Color.clear.frame(height: 110)
        }
    }
}
