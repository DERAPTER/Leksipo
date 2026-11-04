import SwiftUI

struct ProgressHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let days: [ProfileViewModel.DayProgress]

    var body: some View {
        NavigationStack {
            List {
                Text("progress_history_hint".localized()).font(.captionCustom).foregroundStyle(Color.textSecondary)
                    .listRowBackground(Color.cardBackground)
                if days.isEmpty {
                    Text("progress_history_empty".localized()).foregroundStyle(Color.textSecondary)
                        .listRowBackground(Color.cardBackground)
                }
                ForEach(days) { day in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(day.date.formatted(.dateTime.day().month(.wide).year().locale(LanguageManager.shared.currentLanguage.locale)))
                            .font(.bodyCustom.weight(.semibold)).foregroundStyle(Color.textPrimary)
                        Text(String(format: "progress_correct_count".localized(), day.correctAnswers))
                        Text(String(format: "progress_reviews_count".localized(), day.srsReviews))
                    }
                    .font(.captionCustom).foregroundStyle(Color.textSecondary)
                    .listRowBackground(Color.cardBackground)
                }
            }
            .scrollContentBackground(.hidden).background(Color.appBackground)
            .navigationTitle("progress_history".localized()).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("close".localized()) { dismiss() } } }
        }
    }
}
