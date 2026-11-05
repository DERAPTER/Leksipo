//
//  SettingsView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    
    private let themeManager = ThemeManager.shared
    private let languageManager = LanguageManager.shared
    
    @State private var viewModel: SettingsViewModel
    private let onStartTour: (() -> Void)?
    
    @AppStorage("srsNewCardsPerDay") private var srsNewCardsLimit: Int = 20
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    init(container: AppContainer, onStartTour: (() -> Void)? = nil) {
        self.onStartTour = onStartTour
        _viewModel = State(initialValue: SettingsViewModel(
            cardRepository: container.cardRepository,
            groupRepository: container.groupRepository,
            statsRepository: container.statsRepository,
            solveSessionStore: container.solveSessionStore,
            transaction: container.transaction,
            onRestore: { container.didRestoreData() }
        ))
    }
    
    var body: some View {
        mainContent
            .navigationTitle("settings_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.updateStorageSize()
                viewModel.loadStudyLanguages()
            }
            .onChange(of: srsNewCardsLimit) { _, _ in container.srsIntegration?.refresh() }
            .sheet(isPresented: $viewModel.showReleaseNotesSheet) {
                ReleaseNotesSheet()
            }
            .alert("error_title".localized(), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) { Button("ok".localized()) { viewModel.errorMessage = nil } }
            message: { Text(viewModel.errorMessage ?? "") }
            .applyDataAlerts(viewModel: viewModel)
            .applyBackupAlerts(viewModel: viewModel, modelContext: modelContext)
            .applyLanguageAlerts(viewModel: viewModel)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                
                appearanceSection
                
                divider
                
                srsSection
                
                divider
                
                if let integration = container.srsIntegration {
                    ReminderSettingsView(integration: integration)
                    divider
                }

                feedbackSection
                
                divider
                
                studyLanguagesSection

                divider

                languageSection
                
                divider
                
                dataSection
                
                divider
                
                aboutSection
                
                Spacer(minLength: 60)
            }
            .padding(.bottom, 100)
        }
        .background(themeManager.colors.background.ignoresSafeArea())
    }
    
    // MARK: - Sections
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.accent)
            Text("settings_title".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
            Text("settings_description".localized())
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("appearance".localized())
            ThemePickerGridView()
        }
    }
    
    private var srsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("srs_section_title".localized())
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("srs_new_cards_limit".localized())
                        .font(.bodyCustom)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(srsNewCardsLimit)")
                        .font(.bodyCustom.weight(.semibold))
                        .foregroundColor(.accent)
                }
                Slider(
                    value: Binding(
                        get: { Double(srsNewCardsLimit) },
                        set: { srsNewCardsLimit = Int($0) }
                    ),
                    in: 5...100,
                    step: 5
                )
                .tint(.accent)
                
                Text("srs_new_cards_limit_hint".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("feedback_section".localized())
            
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.title2)
                    .foregroundColor(.accent)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("haptics_enabled".localized())
                        .font(.bodyCustom)
                        .foregroundColor(.textPrimary)
                    Text("haptics_enabled_description".localized())
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $hapticsEnabled)
                    .labelsHidden()
                    .tint(.accent)
                    .onChange(of: hapticsEnabled) { _, isOn in
                        if isOn {
                            HapticService.shared.lightImpact()
                        }
                    }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var studyLanguagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("study_languages".localized())
            StudyLanguagePairPicker(pair: Binding(
                get: { viewModel.studyLanguages },
                set: { viewModel.saveStudyLanguages($0) }
            ))
            .disabled(!viewModel.hasLoadedStudyLanguages)
            .padding(.horizontal)
            Text("study_defaults_hint".localized())
                .font(.captionCustom)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal)
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("language".localized())
            
            Text("language_description".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                LanguageButton(
                    language: .english,
                    isSelected: languageManager.currentLanguage == .english
                ) {
                    viewModel.requestLanguageChange(to: .english)
                }
                
                LanguageButton(
                    language: .russian,
                    isSelected: languageManager.currentLanguage == .russian
                ) {
                    viewModel.requestLanguageChange(to: .russian)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("data".localized())
            
            SettingsInfoRow(
                icon: "internaldrive",
                title: "storage_size".localized(),
                value: viewModel.storageSize
            )
            
            SettingsRow(
                icon: "arrow.up.doc",
                title: "backup_export".localized(),
                description: "backup_export_desc".localized(),
                color: .blue
            ) {
                viewModel.prepareExport(context: modelContext)
            }
            
            SettingsRow(
                icon: "arrow.down.doc",
                title: "backup_import".localized(),
                description: "backup_import_desc".localized(),
                color: .blue
            ) {
                viewModel.isImportingBackup = true
            }
            
            SettingsRow(
                icon: "arrow.counterclockwise",
                title: "reset_statistics_short".localized(),
                description: "reset_statistics_description".localized(),
                color: .orange
            ) {
                viewModel.showResetStatsAlert = true
            }
            
            SettingsRow(
                icon: "trash",
                title: "delete_all_data".localized(),
                description: "delete_all_data_description".localized(),
                color: .red
            ) {
                viewModel.showDeleteAllAlert = true
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("about".localized())

            if let onStartTour {
                SettingsRow(icon: "sparkles", title: "tour_replay".localized(),
                            description: "tour_replay_hint".localized(), color: .accent, action: onStartTour)
            }
            
            SettingsInfoRow(
                icon: "info.circle",
                title: "version".localized(),
                value: appVersion
            )
            
            SettingsInfoRow(
                icon: "person",
                title: "developer".localized(),
                value: "tg: @DERAPTER"
            )
            
            SettingsRow(
                icon: "clock.arrow.circlepath",
                title: "release_notes".localized(),
                description: "release_notes_description".localized(),
                color: .accent
            ) {
                viewModel.showReleaseNotesSheet = true
            }
        }
    }
    
    private var divider: some View {
        Divider()
            .background(Color.stroke)
            .padding(.horizontal)
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.titleCustom)
            .foregroundColor(.textPrimary)
            .padding(.horizontal)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.1"
    }
}

// MARK: - View Extensions for Alerts
// Разбиваем алерты на группы, чтобы помочь компилятору.

extension View {
    func applyDataAlerts(viewModel: SettingsViewModel) -> some View {
        self
            .alert(Text(verbatim: "reset_statistics_alert_title".localized()), isPresented: Binding(
                get: { viewModel.showResetStatsAlert },
                set: { viewModel.showResetStatsAlert = $0 }
            )) {
                Button("cancel_button".localized(), role: .cancel) { }
                Button("reset".localized(), role: .destructive) {
                    viewModel.resetStatistics()
                }
            } message: {
                Text(verbatim: "reset_statistics_alert_message".localized())
            }
            .alert(Text(verbatim: "delete_all_alert_title".localized()), isPresented: Binding(
                get: { viewModel.showDeleteAllAlert },
                set: { viewModel.showDeleteAllAlert = $0 }
            )) {
                Button("cancel_button".localized(), role: .cancel) { }
                Button("delete_button".localized(), role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text(verbatim: "delete_all_alert_message".localized())
            }
    }
    
    func applyBackupAlerts(viewModel: SettingsViewModel, modelContext: ModelContext) -> some View {
        self
            .fileExporter(
                isPresented: Binding(
                    get: { viewModel.isExportingBackup },
                    set: { viewModel.isExportingBackup = $0 }
                ),
                document: viewModel.backupDocument,
                contentType: .json,
                defaultFilename: "Leksipo_Backup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
            ) { result in
                if case .failure(let error) = result {
                    viewModel.backupError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: Binding(
                    get: { viewModel.isImportingBackup },
                    set: { viewModel.isImportingBackup = $0 }
                ),
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleImportFile(result)
            }
            .alert(Text(verbatim: "backup_restore_warning_title".localized()), isPresented: Binding(
                get: { viewModel.showRestoreConfirmation },
                set: { viewModel.showRestoreConfirmation = $0 }
            )) {
                Button("cancel".localized(), role: .cancel) { }
                Button("backup_restore_confirm".localized(), role: .destructive) {
                    viewModel.confirmRestore(context: modelContext)
                }
            } message: {
                Text(verbatim: "backup_restore_warning_message".localized())
            }
            .alert(Text(verbatim: "backup_success_title".localized()), isPresented: Binding(
                get: { viewModel.showBackupSuccessAlert },
                set: { viewModel.showBackupSuccessAlert = $0 }
            )) {
                Button("ok".localized()) { }
            } message: {
                Text(verbatim: "backup_restore_success".localized())
            }
            .alert(Text(verbatim: "error_title".localized()), isPresented: Binding(
                get: { viewModel.backupError != nil },
                set: { if !$0 { viewModel.backupError = nil } }
            )) {
                Button("ok".localized()) { viewModel.backupError = nil }
            } message: {
                if let error = viewModel.backupError {
                    Text(verbatim: error)
                }
            }
    }
    
    func applyLanguageAlerts(viewModel: SettingsViewModel) -> some View {
        self
            .alert(Text(verbatim: "change_language_title".localized()), isPresented: Binding(
                get: { viewModel.showLanguageChangeAlert },
                set: { viewModel.showLanguageChangeAlert = $0 }
            )) {
                Button("cancel_button".localized(), role: .cancel) {
                    viewModel.cancelLanguageChange()
                }
                Button("change".localized(), role: .destructive) {
                    viewModel.confirmLanguageChange()
                }
            } message: {
                Text(verbatim: "change_language_message".localized())
            }
    }
}
