//
//  SolveView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SolveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TabBarVisibility.self) private var tabBarVisibility
    @Environment(\.appTour) private var tour
    
    @AppStorage("isReverseCardMode") private var isReverseMode: Bool = false
    
    @State private var viewModel: SolveViewModel
    private let container: AppContainer
    
    @State private var showAddFirstCardSheet = false
    
    init(key: SolveGroupKey, title: String, container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: SolveViewModel(
            key: key,
            title: title,
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
        .navigationTitle(viewModel.groupTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if tour == nil {
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
            tour?.beginPractice(viewModel.key)
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
            tour?.leavePractice()
        }
        .onChange(of: viewModel.state) { _, state in
            if state == .completedWithMistakes || state == .completedWithoutMistakes {
                tour?.advance(from: .answerCard, to: .reviewsTab)
            }
        }
        .alert(
            "continue_session_question".localized(),
            isPresented: $viewModel.showUnfinishedSessionAlert
        ) {
            Button("start_over".localized()) { viewModel.startOver() }
            Button("continue".localized()) { viewModel.continueSession() }
        } message: {
            Text(String(
                format: "continue_session_message".localized(),
                viewModel.successCount + viewModel.failCount,
                viewModel.totalProgress
            ))
        }
        .sheet(isPresented: $showAddFirstCardSheet) {
            AddFirstCardSheet(
                group: userGroupForCurrentKey,
                systemType: systemTypeForCurrentKey,
                cardRepository: container.cardRepository,
                achievementsService: container.achievementsService,
                transaction: container.transaction,
                onComplete: { viewModel.onAppear() }
            )
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .empty:
            if case .practice = viewModel.key {
                ContentUnavailableView("no_cards_found".localized(), systemImage: "rectangle.stack")
            } else {
                EmptyGroupView(
                    groupTitle: viewModel.groupTitle,
                    onAddFirstCard: { showAddFirstCardSheet = true },
                    onDismiss: { dismiss() }
                )
            }
            
        case .completedWithoutMistakes, .completedWithMistakes:
            if tour != nil {
                ContentUnavailableView("tour_practice_done".localized(), systemImage: "checkmark.circle")
            } else {
                ResultView(
                    successCount: viewModel.successCount,
                    failCount: viewModel.failCount,
                    progressFraction: viewModel.progressFraction,
                    hasMistakes: viewModel.state == .completedWithMistakes,
                    onRestart: { viewModel.restartFromResult() },
                    onRestartMistakes: viewModel.state == .completedWithMistakes
                        ? { viewModel.restartMistakesFromResult() }
                        : nil
                )
            }
            
        case .solving:
            if tour != nil {
                GeometryReader { geometry in
                    swipeSolvingScreen(cardHeight: min(480, max(0, geometry.size.height - 124)))
                }
            } else {
                swipeSolvingScreen()
            }
        }
    }
    
    // MARK: - Swipe mode
    
    private func swipeSolvingScreen(cardHeight: CGFloat = 480) -> some View {
        VStack {
            Text("\(viewModel.currentProgress)/\(viewModel.totalProgress)")
                .font(.titleCustom)
                .foregroundColor(.textSecondary)
            
            AnswerCounterView(
                correctCount: viewModel.successCount,
                wrongCount: viewModel.failCount,
                percentageOfMove: viewModel.percentageOfMove
            )
            
            Spacer()
            
            swipeCardArea(height: cardHeight)
            
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private func swipeCardArea(height: CGFloat) -> some View {
        if let card = viewModel.currentCard {
            SwipeableCardView(
                card: card,
                percentageOfMove: viewModel.percentageOfMove,
                isReversed: tour == nil && isReverseMode,
                onToggleFavourite: { viewModel.toggleFavouriteCurrentCard() },
                cardHeight: height,
                onFlip: { tour?.advance(from: .flipCard, to: .answerCard) }
            )
            .tourHighlight(tour?.step == .flipCard, cornerRadius: 30)
            .offset(x: viewModel.offsetOfCardX, y: viewModel.offsetOfCardY)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.offsetOfCardX)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.offsetOfCardY)
            .gesture(swipeGesture)
        } else {
            Color.clear.frame(width: 320, height: height)
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged {
                guard tour == nil || tour?.step == .answerCard else { return }
                viewModel.onDragChanged($0)
            }
            .onEnded { value in
                guard tour == nil || tour?.step == .answerCard else { return }
                let decision = viewModel.onDragEnded(value)
                handleSwipeDecision(decision)
            }
    }
    
    private func handleSwipeDecision(_ decision: SolveViewModel.SwipeDecision) {
        switch decision {
        case .flyLeft:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.offsetOfCardX = -1000
            }
            Task { await viewModel.commitSwipe(.flyLeft) }
        case .flyRight:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.offsetOfCardX = 1000
            }
            Task { await viewModel.commitSwipe(.flyRight) }
        case .reset:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.offsetOfCardX = 0
                viewModel.offsetOfCardY = 0
            }
            Task { await viewModel.commitSwipe(.reset) }
        }
    }
    
    // MARK: - Helpers
    
    private var userGroupForCurrentKey: CardGroup? {
        if case .user(let id) = viewModel.key {
            return try? container.groupRepository.fetch(id: id)
        }
        return nil
    }
    
    private var systemTypeForCurrentKey: SystemGroupType? {
        if case .system(let type) = viewModel.key {
            return type
        }
        return nil
    }
}
