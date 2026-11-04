import SwiftUI

struct ProgressCardListView: View {
    @Environment(AppContainer.self) private var container
    @Bindable var viewModel: ProfileViewModel
    let pair: StudyLanguagePair?
    let filter: ProfileViewModel.CardFilter
    @State private var practiceCardIDs: [UUID] = []
    @State private var showPractice = false

    var body: some View {
        List {
            if filter == .attention || filter == .longTerm {
                Text((filter == .attention ? "progress_attention_hint" : "progress_long_term_hint").localized())
                    .font(.captionCustom).foregroundStyle(Color.textSecondary)
                    .listRowBackground(Color.cardBackground)
            }
            if let pair {
                Text(pair.displayName).font(.captionCustom).foregroundStyle(Color.textSecondary)
                    .listRowBackground(Color.cardBackground)
            }
            let cards = viewModel.cards(for: pair, filter: filter)
            if filter == .attention && !cards.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        practiceCardIDs = cards.map(\.id)
                        showPractice = true
                    } label: {
                        Label("progress_practice_all".localized(), systemImage: "play.fill")
                            .font(.bodyCustom.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accent)
                    Text("progress_practice_hint".localized())
                        .font(.captionCustom).foregroundStyle(Color.textSecondary)
                }
                .listRowBackground(Color.cardBackground)
            }
            if cards.isEmpty {
                Text("no_cards_found".localized()).foregroundStyle(Color.textSecondary)
                    .listRowBackground(Color.cardBackground)
            }
            ForEach(cards) { card in
                Group {
                    if filter == .attention {
                        HStack {
                            cardSummary(card)
                            Spacer(minLength: 12)
                            NavigationLink {
                                editor(card)
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(Color.accent)
                            }
                            .accessibilityLabel("edit_card".localized() + ": " + card.originWord)
                            .frame(width: 44)
                        }
                    } else {
                        NavigationLink { editor(card) } label: { cardSummary(card) }
                    }
                }
                .listRowBackground(Color.cardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(filter.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPractice) {
            SolveView(key: .practice(practiceCardIDs), title: "progress_attention".localized(), container: container)
        }
        .onAppear { viewModel.load() }
    }

    private func editor(_ card: Card) -> some View {
        EditCardView(card: card, cardRepository: container.cardRepository,
                     groupRepository: container.groupRepository, onComplete: { viewModel.load() })
    }

    private func cardSummary(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(card.originWord).font(.bodyCustom.weight(.semibold)).foregroundStyle(Color.textPrimary)
            Text(card.translatedWord).font(.bodyCustom).foregroundStyle(Color.textSecondary)
            if pair == nil {
                Text(card.languagePair.displayName).font(.captionCustom).foregroundStyle(Color.textSecondary)
            }
            if filter == .attention {
                Text(String(format: "progress_card_errors".localized(), card.wrongCount, card.totalAttempts))
                    .font(.captionCustom).foregroundStyle(Color.textSecondary)
            } else if !card.isNewInSRS {
                Text(String(format: "progress_card_interval".localized(), card.intervalDays))
                    .font(.captionCustom).foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
