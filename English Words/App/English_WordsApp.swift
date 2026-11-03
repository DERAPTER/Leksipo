//
//  English_WordsApp.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct English_WordsApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var startup = AppStartup()
    @State private var router = AppRouter()
    @State private var showRecoveryImporter = false
    @State private var recoveryData: Data?
    @State private var showRecoveryConfirmation = false
    @State private var recoveryError: String?
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if let container = startup.app, let model = startup.container {
                    RootView()
                        .environment(container)
                        .modelContainer(model)
                        .transition(.opacity)
                } else if let error = startup.errorMessage {
                    recoveryView(error: error)
                } else {
                    SplashGreetingView()
                        .transition(.opacity)
                }
            }
            .environment(router)
            .onOpenURL { router.handle($0) }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                startup.app?.srsIntegration?.refresh(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                startup.app?.srsIntegration?.refresh(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
                startup.app?.srsIntegration?.refresh(force: true)
            }
            .task {
                guard ProcessInfo.processInfo.environment["ENGLISH_WORDS_TEST_HOST"] != "1" else { return }
                startup.start()
                startup.app?.srsIntegration?.refresh(force: true)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .active {
                startup.app?.srsIntegration?.refresh(force: true)
            }
        }
    }
    
    private func recoveryView(error: String) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.largeTitle)
                Text("startup_failed_title".localized()).font(.title)
                Text("startup_failed_help".localized())
                Text(error).font(.caption).textSelection(.enabled)
                Button("retry_action".localized()) { startup.start() }
                ShareLink(item: error) { Text("startup_share_error".localized()) }
                if startup.container != nil {
                    Button("backup_import".localized()) { showRecoveryImporter = true }
                }
            }
            .padding()
        }
        .fileImporter(isPresented: $showRecoveryImporter, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                _ = try BackupService.validatedBackup(from: data)
                recoveryData = data
                showRecoveryConfirmation = true
            } catch { recoveryError = error.localizedDescription }
        }
        .alert("backup_restore_warning_title".localized(), isPresented: $showRecoveryConfirmation) {
            Button("cancel".localized(), role: .cancel) { recoveryData = nil }
            Button("backup_restore_confirm".localized(), role: .destructive) {
                if let recoveryData { startup.restore(recoveryData) }
                recoveryData = nil
            }
        } message: { Text("backup_restore_warning_message".localized()) }
        .alert("error_title".localized(), isPresented: Binding(
            get: { recoveryError != nil }, set: { if !$0 { recoveryError = nil } }
        )) { Button("ok".localized()) { recoveryError = nil } }
        message: { Text(recoveryError ?? "") }
    }

}
