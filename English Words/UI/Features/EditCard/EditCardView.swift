//
//  EditCardView.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: EditCardViewModel
    private let onComplete: () -> Void
    
    init(
        card: Card,
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        onComplete: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        _viewModel = State(initialValue: EditCardViewModel(
            card: card,
            cardRepository: cardRepository,
            groupRepository: groupRepository
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                
                wordFields
                
                groupsSection
                
                CardStatsSection(card: viewModel.card)
                
                saveButton
                
                deleteButton
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("edit_card".localized())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel".localized()) {
                    dismiss()
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .alert("delete_card_confirmation".localized(), isPresented: $viewModel.showDeleteConfirmation) {
            Button("cancel".localized(), role: .cancel) { }
            Button("delete".localized(), role: .destructive) {
                if viewModel.delete() {
                    onComplete()
                    dismiss()
                }
            }
        } message: {
            Text("delete_card_message".localized())
        }
        .alert("duplicate_card_title".localized(), isPresented: $viewModel.showDuplicateAlert) {
            Button("ok".localized(), role: .cancel) { }
        } message: {
            Text("duplicate_card_message".localized())
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        Text("edit_card".localized())
            .font(.largeTitleCustom)
            .foregroundColor(.textPrimary)
            .padding(.top, 20)
    }
    
    private var wordFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            WordInputField(
                title: "original_word".localized(),
                placeholder: "enter_word".localized(),
                text: $viewModel.editedOrigin
            )
            
            WordInputField(
                title: "translation".localized(),
                placeholder: "enter_translation".localized(),
                text: $viewModel.editedTranslated
            )
            
            Divider()
                .background(Color.stroke)
                .padding(.vertical, 4)
            
            Text("optional_description_section".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
            
            MultilineInputField(
                title: "original_description".localized(),
                placeholder: "enter_original_description".localized(),
                text: $viewModel.editedOriginDescription
            )
            
            MultilineInputField(
                title: "translated_description".localized(),
                placeholder: "enter_translated_description".localized(),
                text: $viewModel.editedTranslatedDescription
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("groups_management".localized())
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            if !viewModel.hasLoadedGroups {
                VStack(alignment: .leading, spacing: 8) {
                    Text("edit_card_groups_load_failed".localized())
                        .font(.bodyCustom)
                        .foregroundColor(.red)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.captionCustom)
                            .foregroundColor(.textSecondary)
                    }

                    Button("retry_action".localized()) {
                        viewModel.onAppear()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            
            if viewModel.hasLoadedGroups && !viewModel.selectedGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("selected_groups".localized())
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.selectedGroups) { group in
                            GroupChip(group: group, isSelected: true) {
                                withAnimation {
                                    viewModel.toggleGroup(group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if viewModel.hasLoadedGroups && !viewModel.availableGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("available_groups".localized())
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.availableGroups) { group in
                            GroupChip(group: group, isSelected: false) {
                                withAnimation {
                                    viewModel.toggleGroup(group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if viewModel.hasLoadedGroups && viewModel.selectedGroups.isEmpty && viewModel.availableGroups.isEmpty {
                Text("no_groups_available".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal)
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            if viewModel.save() {
                onComplete()
                dismiss()
            }
        } label: {
            Text("save_changes".localized())
                .font(.bodyCustom.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSave ? Color.accent : Color.gray)
                .cornerRadius(16)
        }
        .disabled(!viewModel.canSave)
        .padding(.horizontal)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.title2)
                Text("delete_card".localized())
                    .font(.bodyCustom)
            }
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
