//
//  EditGroupView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct EditGroupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: EditGroupViewModel
    private let onComplete: () -> Void
    
    init(
        group: CardGroup,
        groupRepository: GroupRepository,
        onComplete: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        _viewModel = State(initialValue: EditGroupViewModel(
            group: group,
            groupRepository: groupRepository
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    
                    nameEditor

                    StudyLanguagePairPicker(pair: $viewModel.editedLanguagePair).padding(.horizontal)
                    Text("study_group_change_hint".localized())
                        .font(.captionCustom)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal)
                    
                    infoSection
                    
                    saveButton

                    shareButton
                    
                    deleteButton
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("group_settings".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close".localized()) { dismiss() }
                }
            }
            .alert(
                "delete_group_confirmation".localized(),
                isPresented: $viewModel.showDeleteConfirmation
            ) {
                Button("cancel".localized(), role: .cancel) { }
                Button("delete".localized(), role: .destructive) {
                    if viewModel.delete() {
                        onComplete()
                        dismiss()
                    }
                }
            } message: {
                Text("delete_group_message".localized())
            }
            .alert("study_group_change_title".localized(), isPresented: $viewModel.showLanguageConfirmation) {
                Button("cancel".localized(), role: .cancel) { }
                Button("save_changes".localized()) {
                    if viewModel.save(confirmLanguageChange: true) { onComplete() }
                }
            } message: { Text("study_group_change_hint".localized()) }
            .alert(
                "error_title".localized(),
                isPresented: $viewModel.showErrorAlert
            ) {
                Button("ok".localized(), role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        Text(viewModel.group.name)
            .font(.largeTitleCustom)
            .foregroundColor(.textPrimary)
            .padding(.top, 20)
    }
    
    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("group_name_label".localized())
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .padding(.horizontal)
            
            TextField("enter_group_name".localized(), text: $viewModel.editedName)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.stroke, lineWidth: 1)
                )
                .padding(.horizontal)
                .onSubmit {
                    if viewModel.canSave {
                        _ = viewModel.save()
                    }
                }
            
            if viewModel.canSave {
                HStack {
                    Text("unsaved_changes".localized())
                        .font(.captionCustom)
                        .foregroundColor(.accent)
                    
                    Spacer()
                    
                    Button {
                        if viewModel.save() {
                            onComplete()
                        }
                    } label: {
                        Text("save".localized())
                            .font(.captionCustom)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.accent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSave)
    }
    
    private var infoSection: some View {
        HStack {
            Text("cards_in_group".localized())
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
            Spacer()
            Text("\(viewModel.group.cards.count)")
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var saveButton: some View {
        Button {
            if viewModel.save() {
                onComplete()
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
    
    private var shareButton: some View {
        ShareLink(item: SharedGroupDocument(group: viewModel.group),
                  preview: SharePreview(viewModel.group.name, image: Image(systemName: "rectangle.stack"))) {
            Label("share_group".localized(), systemImage: "square.and.arrow.up")
                .font(.bodyCustom)
                .foregroundStyle(Color.accent)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.title2)
                Text("delete_group".localized())
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
