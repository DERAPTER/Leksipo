//
//  AddGroupSheet.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct AddGroupSheet: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.appTour) private var tour
    @State private var languagePair = StudyLanguagePair.legacy
    @State private var didLoadLanguages = false
    @Bindable var viewModel: GroupsListViewModel
    @Binding var isPresented: Bool
    
    @State private var groupName = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                
                    inputField

                    if tour == nil {
                        StudyLanguagePairPicker(pair: $languagePair).padding(.horizontal)
                    } else {
                        Text(languagePair.displayName)
                            .font(.captionCustom)
                            .foregroundStyle(Color.textSecondary)
                    }
                
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.captionCustom)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                
                    Spacer()
                
                    createButton
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                if let tour {
                    TourSpeech(message: "tour_group_form".localized(), onSkip: { tour.requestExit() })
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.appBackground)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if tour == nil { isFocused = true }
                guard !didLoadLanguages else { return }
                do {
                    languagePair = try container.statsRepository.settings().languagePair
                    if tour != nil { groupName = "tour_example_group".localized() }
                    didLoadLanguages = true
                } catch { errorMessage = error.localizedDescription }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.accent)
            Text("create_new_group".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
            Text("add_new_group_description".localized())
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("group_name".localized())
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
            TextField("enter_group_name".localized(), text: $groupName)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.stroke, lineWidth: 1)
                )
                .focused($isFocused)
        }
        .padding(.horizontal)
    }
    
    private var createButton: some View {
        Button(action: createGroup) {
            Text("create_group".localized())
                .font(.bodyCustom.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(groupName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.accent)
                .cornerRadius(16)
        }
        .disabled(!didLoadLanguages || groupName.trimmingCharacters(in: .whitespaces).isEmpty)
        .tourHighlight(tour != nil)
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    private func createGroup() {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        do {
            let group = try viewModel.createGroup(name: trimmed, languagePair: languagePair)
            tour?.createdGroup(group.id)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
