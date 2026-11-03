//
//  ImportDataView.swift
//  Leksipo
//
//  Created by Егор Халиков on 21.10.2026.
//

//
//  ImportDataView.swift
//  Leksipo
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var container
    @State private var didLoadLanguages = false
    @State private var viewModel: ImportDataViewModel
    @State private var showHelpSheet = false
    
    // Состояния для анимации копирования
    @State private var isTemplateCopied = false
    @State private var isPromptCopied = false
    
    init(container: AppContainer, onComplete: @escaping () -> Void) {
        _viewModel = State(initialValue: ImportDataViewModel(
            cardRepository: container.cardRepository,
            groupRepository: container.groupRepository,
            transaction: container.transaction,
            achievementsService: container.achievementsService,
            onComplete: onComplete
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StudyLanguagePairPicker(pair: $viewModel.languagePair).padding(.horizontal)
                    Text("import_language_hint".localized()).font(.captionCustom)
                        .foregroundStyle(Color.textSecondary).padding(.horizontal)
                
                    // 1. Кнопки копирования (Шаблон и Промпт)
                    VStack(spacing: 8) {
                        // Кнопка: Скопировать шаблон JSON
                        Button {
                            UIPasteboard.general.string = viewModel.jsonTemplate
                            withAnimation { isTemplateCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { isTemplateCopied = false }
                            }
                        } label: {
                            HStack {
                                Image(systemName: isTemplateCopied ? "checkmark" : "doc.on.doc")
                                Text(isTemplateCopied ? "import_copied".localized() : "import_copy_template_top".localized())
                            }
                            .font(.captionCustom.weight(.medium))
                            .foregroundColor(isTemplateCopied ? .green : .accent)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.cardBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isTemplateCopied ? Color.green : Color.accent, lineWidth: 1)
                            )
                        }

                        // Кнопка: Скопировать промпт для нейросети (цвет изменен на accent)
                        Button {
                            UIPasteboard.general.string = viewModel.aiPromptTemplate
                            withAnimation { isPromptCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { isPromptCopied = false }
                            }
                        } label: {
                            HStack {
                                Image(systemName: isPromptCopied ? "checkmark" : "sparkles")
                                Text(isPromptCopied ? "import_copied".localized() : "import_copy_prompt_top".localized())
                            }
                            .font(.captionCustom.weight(.medium))
                            .foregroundColor(isPromptCopied ? .green : .accent)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.cardBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isPromptCopied ? Color.green : Color.accent, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 12)
                    // Убрали .padding(.horizontal, 20), так как кнопки больше не растягиваются

                    Spacer().frame(height: 10)

                    // 2. Главная кнопка "Вставить из буфера"
                    Button {
                        viewModel.pasteFromClipboard()
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.system(size: 40))

                            Text("import_paste_from_clipboard".localized())
                                .font(.bodyCustom.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color.accent)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                
                    // Индикатор того, что текст вставлен
                    if !viewModel.jsonText.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("import_pasted_success".localized())
                                .font(.captionCustom)
                                .foregroundColor(.textSecondary)
                        }
                        .transition(.opacity)
                    }
                
                    // Разделитель "или"
                    HStack {
                        Rectangle().fill(Color.stroke).frame(height: 1)
                        Text("import_or".localized())
                            .font(.captionCustom)
                            .foregroundColor(.textSecondary)
                        Rectangle().fill(Color.stroke).frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                
                    // 3. Кнопка загрузки файла
                    Button {
                        viewModel.showFileImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("import_select_file".localized())
                        }
                        .font(.bodyCustom.weight(.medium))
                        .foregroundColor(.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accent, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    // 4. Кнопка "Как это работает"
                    Button {
                        showHelpSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text("import_how_it_works".localized())
                        }
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 10)
                
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.captionCustom)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                
                    Spacer()
                }
            }
            .onAppear {
                guard !didLoadLanguages else { return }
                do {
                    viewModel.languagePair = try container.statsRepository.settings().languagePair
                    didLoadLanguages = true
                } catch { viewModel.errorMessage = error.localizedDescription }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("import_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("import_btn".localized()) {
                        viewModel.startImport(from: viewModel.jsonText)
                    }
                    // Блокируем кнопку импорта, если текст не вставлен
                    .disabled(!didLoadLanguages || viewModel.jsonText.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showHelpSheet) {
                ImportHelpView(jsonTemplate: viewModel.jsonTemplate, aiPromptTemplate: viewModel.aiPromptTemplate)
            }
            .fileImporter(
                isPresented: $viewModel.showFileImporter,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleFileSelection(result)
            }
            .alert("import_preview_title".localized(), isPresented: $viewModel.showDuplicateAlert) {
                Button("cancel".localized(), role: .cancel) { }
                Button("ok".localized()) { viewModel.confirmImportWithDuplicates() }
            } message: {
                Text(viewModel.previewMessage)
            }
            .alert("import_success_title".localized(), isPresented: $viewModel.showSuccessAlert) {
                Button("ok".localized()) { dismiss() }
            } message: {
                Text(viewModel.successMessage)
            }
        }
    }
}
