import SwiftUI

struct StudyLanguagePairPicker: View {
    @Binding var pair: StudyLanguagePair

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudyLanguagePicker(title: "study_learning_language".localized(), selection: $pair.learning)
            StudyLanguagePicker(title: "study_translation_language".localized(), selection: $pair.translation)
        }
    }
}

private struct StudyLanguagePicker: View {
    let title: String
    @Binding var selection: StudyLanguage
    @State private var isPresented = false

    var body: some View {
        Button { isPresented = true } label: {
            HStack {
                Text(title).foregroundStyle(Color.textPrimary)
                Spacer()
                Text(selection.displayName).foregroundStyle(Color.accent)
                Image(systemName: "chevron.up.chevron.down").foregroundStyle(Color.textSecondary)
            }
            .font(.bodyCustom)
            .padding(12)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            StudyLanguageList(title: title, selection: $selection)
        }
    }
}

private struct StudyLanguageList: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var selection: StudyLanguage
    @State private var query = ""

    private var languages: [StudyLanguage] {
        Set(StudyLanguage.all + [selection]).filter {
            query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) ||
                $0.nativeName.localizedCaseInsensitiveContains(query) || $0.code.localizedCaseInsensitiveContains(query)
        }.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List(languages) { language in
                Button {
                    selection = language
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(language.displayName).foregroundStyle(Color.textPrimary)
                            Text(language.nativeName).font(.caption).foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        if language == selection { Image(systemName: "checkmark").foregroundStyle(Color.accent) }
                    }
                }
                .listRowBackground(Color.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .searchable(text: $query, prompt: "study_language_search".localized())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close".localized()) { dismiss() }
                }
            }
        }
    }
}
