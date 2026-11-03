//
//  ImportHelpView.swift
//  Leksipo
//
//  Created by Егор Халиков on 21.10.2026.
//

import SwiftUI

struct ImportHelpView: View {
    @Environment(\.dismiss) private var dismiss
    let jsonTemplate: String
    let aiPromptTemplate: String
    
    // Состояния для кнопок копирования
    @State private var isJsonCopied = false
    @State private var isPromptCopied = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. Текст инструкции
                    Text("import_help_desc".localized())
                        .font(.bodyCustom)
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 2. Блок с JSON
                    VStack(alignment: .leading, spacing: 12) {
                        Text("import_help_template_title".localized())
                            .font(.bodyCustom.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text(jsonTemplate)
                            .font(.system(.caption, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stroke, lineWidth: 1)
                            )
                        
                        copyButton(text: jsonTemplate, isCopied: $isJsonCopied, label: "import_copy_template".localized())
                    }
                    
                    Divider().background(Color.stroke)
                    
                    // 3. Блок с промптом для нейросети
                    VStack(alignment: .leading, spacing: 12) {
                        Text("import_help_prompt_title".localized())
                            .font(.bodyCustom.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("import_help_prompt_desc".localized())
                            .font(.captionCustom)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(aiPromptTemplate)
                            .font(.system(.caption, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stroke, lineWidth: 1)
                            )
                        
                        copyButton(text: aiPromptTemplate, isCopied: $isPromptCopied, label: "import_copy_prompt".localized())
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("import_how_it_works".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close".localized()) { dismiss() }
                }
            }
        }
    }
    
    // Универсальная кнопка копирования, чтобы не дублировать код
    private func copyButton(text: String, isCopied: Binding<Bool>, label: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            withAnimation { isCopied.wrappedValue = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { isCopied.wrappedValue = false }
            }
        } label: {
            HStack {
                Image(systemName: isCopied.wrappedValue ? "checkmark" : "doc.on.doc")
                Text(isCopied.wrappedValue ? "import_copied".localized() : label)
            }
            .font(.bodyCustom.weight(.medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isCopied.wrappedValue ? Color.green : Color.accent)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
