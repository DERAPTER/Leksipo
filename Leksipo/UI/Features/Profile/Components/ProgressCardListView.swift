import SwiftUI

struct ProgressCardListView: View {
    @Environment(AppContainer.self) private var container
    @Bindable var viewModel: ProfileViewModel
    let pair: StudyLanguagePair?
    let filter: ProfileViewModel.CardFilter

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
            if cards.isEmpty {
                Text("no_cards_found".localized()).foregroundStyle(Color.textSecondary)
                    .listRowBackground(Color.cardBackground)
            }
            ForEach(cards) { card in
                NavigationLink {
                    EditCardView(card: card, cardRepository: container.cardRepository,
                                 groupRepository: container.groupRepository, onComplete: { viewModel.load() })
                } label: {
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
                .listRowBackground(Color.cardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(filter.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }
}
