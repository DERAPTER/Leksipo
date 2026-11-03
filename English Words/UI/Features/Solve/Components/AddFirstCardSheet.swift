//
//  AddFirstCardSheet.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

/// Упрощённый sheet для добавления первой карточки в пустую группу.
/// Создаёт карточку сразу в целевой группе. Если группа системная,
/// добавляет в "All Cards" и (для Favourites) ставит isFavourite.
struct AddFirstCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let group: CardGroup?
    let systemType: SystemGroupType?
    @State private var viewModel: AddFirstCardViewModel
    let onComplete: () -> Void
    
    @State private var originWord = ""
    @State private var translatedWord = ""
    @State private var originDescription = ""
    @State private var translatedDescription = ""
    @State private var isSaving = false
    
    init(group: CardGroup?, systemType: SystemGroupType?, cardRepository: CardRepository,
         achievementsService: AchievementsService, transaction: PersistenceTransaction,
         onComplete: @escaping () -> Void) {
        self.group = group
        self.systemType = systemType
        self.onComplete = onComplete
        _viewModel = State(initialValue: AddFirstCardViewModel(cards: cardRepository, transaction: transaction, achievements: achievementsService))
    }

    private var canSave: Bool {
        !originWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translatedWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                
                VStack(alignment: .leading, spacing: 16) {
                    WordInputField(
                        title: "original_word".localized(),
                        placeholder: "enter_word".localized(),
                        text: $originWord
                    )
                    
                    WordInputField(
                        title: "translation".localized(),
                        placeholder: "enter_translation".localized(),
                        text: $translatedWord
                    )
                    
                    MultilineInputField(
                        title: "original_description".localized(),
                        placeholder: "enter_original_description".localized(),
                        text: $originDescription
                    )
                    
                    MultilineInputField(
                        title: "translated_description".localized(),
                        placeholder: "enter_translated_description".localized(),
                        text: $translatedDescription
                    )
                }
                .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.captionCustom)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                saveButton
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("add_card".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("add_first_card_title".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
                .padding(.top, 20)
                .multilineTextAlignment(.center)
            
            Text(String(
                format: "add_first_card_subtitle".localized(),
                displayGroupName
            ))
            .font(.bodyCustom)
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }
    
    private var saveButton: some View {
        Button(action: save) {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
                Text("save_and_start".localized())
                    .font(.bodyCustom.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSave ? Color.accent : Color.gray)
            .cornerRadius(16)
        }
        .disabled(!canSave || isSaving)
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    // MARK: - Helpers
    
    private var displayGroupName: String {
        if let systemType {
            return systemType.localizedNameKey.localized()
        }
        return group?.name ?? ""
    }
    
    private func save() {
        let trimmedOrigin = originWord.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslated = translatedWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOrigin.isEmpty, !trimmedTranslated.isEmpty else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        if viewModel.save(origin: trimmedOrigin, translated: trimmedTranslated,
                          originDescription: originDescription, translatedDescription: translatedDescription,
                          group: group, isFavourite: systemType == .favourites) {
            onComplete()
            dismiss()
        }
    }
}
