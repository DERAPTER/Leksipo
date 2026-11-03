//
//  AddGroupSheet.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct AddGroupSheet: View {
    @Bindable var viewModel: GroupsListViewModel
    @Binding var isPresented: Bool
    
    @State private var groupName = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                
                inputField
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.captionCustom)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                createButton
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                isFocused = true
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
        .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    private func createGroup() {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        do {
            try viewModel.createGroup(name: trimmed)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
