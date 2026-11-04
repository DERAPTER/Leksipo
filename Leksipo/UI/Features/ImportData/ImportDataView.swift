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
    private enum Source: String, CaseIterable {
        case table, json
        var title: String { self == .table ? "table_import_source".localized() : "JSON" }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var container
    @State private var didLoadLanguages = false
    @State private var viewModel: ImportDataViewModel
    @State private var tableViewModel: TableImportViewModel
    @State private var source = Source.table
    @State private var languageLoadError: String?
    @State private var showHelpSheet = false
    private let initialFileURL: URL?
    
    // Состояния для анимации копирования
    @State private var isTemplateCopied = false
    @State private var isPromptCopied = false
    
    init(container: AppContainer, initialFileURL: URL? = nil, onComplete: @escaping () -> Void) {
        self.initialFileURL = initialFileURL
        _source = State(initialValue: initialFileURL == nil ? .table : .json)
        let importer = ImportDataViewModel(
            cardRepository: container.cardRepository,
            groupRepository: container.groupRepository,
            transaction: container.transaction,
            achievementsService: container.achievementsService,
            onComplete: onComplete
        )
        _viewModel = State(initialValue: importer)
        _tableViewModel = State(initialValue: TableImportViewModel(
            cards: container.cardRepository, groups: container.groupRepository,
            importGroups: { try importer.importPreparedGroups($0) }
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let initialFileURL {
                        sharedFileContent(initialFileURL)
                    } else {
                        Picker("import_title".localized(), selection: $source) {
                            ForEach(Source.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented).padding(.horizontal)
                        if source == .table {
                            TableImportContent(viewModel: tableViewModel, onClose: { dismiss() })
                        } else {
                            jsonContent
                        }
                    }
                    if let languageLoadError {
                        Text(languageLoadError).font(.captionCustom).foregroundStyle(Color.red).padding(.horizontal)
                    }
                }
                .padding(.top, 12)
                .disabled(viewModel.isLoadingFile)
            }
            .overlay {
                if viewModel.isLoadingFile {
                    ProgressView("group_import_loading".localized())
                        .padding().background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .task(id: initialFileURL) {
                if !didLoadLanguages {
                    do {
                        viewModel.languagePair = try container.statsRepository.settings().languagePair
                        tableViewModel.languagePair = viewModel.languagePair
                        languageLoadError = nil
                        didLoadLanguages = true
                    } catch { languageLoadError = error.localizedDescription }
                }
                if let initialFileURL { await viewModel.loadSharedFile(initialFileURL) }
            }
            .onChange(of: source) { _, source in
                if source == .json { viewModel.languagePair = tableViewModel.languagePair }
                else { tableViewModel.languagePair = viewModel.languagePair }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle((initialFileURL == nil ? "import_title" : "group_import_title").localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button((initialFileURL == nil ? "import_btn" : "group_import_confirm").localized()) {
                        if initialFileURL != nil { viewModel.confirmImportWithDuplicates() }
                        else if source == .table { tableViewModel.importTable() }
                        else { viewModel.startImport(from: viewModel.jsonText) }
                    }
                    // Блокируем кнопку импорта, если текст не вставлен
                    .disabled(!didLoadLanguages || viewModel.isLoadingFile || (initialFileURL != nil
                        ? viewModel.previewCardCounts == nil || viewModel.showSuccessAlert
                        : (source == .table ? !tableViewModel.canImport : viewModel.jsonText.isEmpty)))
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
            .alert("import_preview_title".localized(), isPresented: Binding(
                get: { initialFileURL == nil && viewModel.showDuplicateAlert },
                set: { viewModel.showDuplicateAlert = $0 }
            )) {
                Button("cancel".localized(), role: .cancel) { }
                Button("import_btn".localized()) { viewModel.confirmImportWithDuplicates() }
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

    private func sharedFileContent(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(url.lastPathComponent, systemImage: "doc.text")
                .font(.bodyCustom.weight(.semibold))
            if let counts = viewModel.previewCardCounts {
                Text(viewModel.previewGroupDetails).font(.bodyCustom)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .top, spacing: 24) {
                    importCount(counts.new, title: "group_import_new".localized())
                    importCount(counts.existing, title: "group_import_existing".localized())
                }
                Text("group_import_merge_hint".localized()).font(.captionCustom)
                    .foregroundStyle(Color.textSecondary)
            }
            if let error = viewModel.errorMessage {
                Text(error).font(.bodyCustom).foregroundStyle(Color.red)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func importCount(_ count: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)").font(.title.weight(.semibold)).foregroundStyle(Color.accent)
            Text(title).font(.captionCustom).foregroundStyle(Color.textSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var jsonContent: some View {
        VStack(spacing: 20) {
            Text("table_import_json_hint".localized()).font(.captionCustom)
                .foregroundStyle(Color.textSecondary).padding(.horizontal)
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
}
