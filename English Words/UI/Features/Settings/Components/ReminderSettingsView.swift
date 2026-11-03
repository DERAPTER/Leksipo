import SwiftUI

struct ReminderSettingsView: View {
    let integration: SRSIntegrationService
    @Environment(\.openURL) private var openURL
    @State private var enabled: Bool
    @State private var time: Date
    @State private var permissionTask: Task<Void, Never>?

    init(integration: SRSIntegrationService) {
        self.integration = integration
        _enabled = State(initialValue: integration.remindersEnabled)
        _time = State(initialValue: StudyDay.calendar.date(bySettingHour: integration.reminderHour,
                                                          minute: integration.reminderMinute, second: 0, of: .now) ?? .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("srs_reminders_enabled".localized(), isOn: $enabled)
                .tint(.accent)
            Text("srs_reminders_help".localized())
                .font(.captionCustom)
                .foregroundStyle(Color.textSecondary)
            if enabled {
                DatePicker("srs_reminder_time".localized(), selection: $time, displayedComponents: .hourAndMinute)
                Text(statusText)
                    .font(.captionCustom)
                    .foregroundStyle(Color.textSecondary)
                if integration.notifications.authorizationStatus == .denied {
                    Button("srs_open_system_settings".localized()) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                } else if integration.notifications.authorizationStatus == .notDetermined {
                    Button("srs_allow_notifications".localized(), action: requestPermission)
                }
            }
            if integration.errorMessage != nil || integration.notifications.errorMessage != nil {
                Text("srs_integration_failed".localized())
                    .font(.captionCustom)
                    .foregroundStyle(.red)
                Button("retry_action".localized()) { integration.refresh(force: true) }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
        .task { await integration.notifications.refreshAuthorization() }
        .onChange(of: enabled) { _, value in
            integration.setRemindersEnabled(value)
            permissionTask?.cancel()
            if value { requestPermission() }
        }
        .onChange(of: time) { _, value in
            integration.setReminderTime(hour: StudyDay.calendar.component(.hour, from: value),
                                        minute: StudyDay.calendar.component(.minute, from: value))
        }
        .onDisappear { permissionTask?.cancel() }
    }

    private func requestPermission() {
        permissionTask?.cancel()
        permissionTask = Task {
            _ = await integration.notifications.requestPermission()
            guard !Task.isCancelled else { return }
            integration.refresh(force: true)
        }
    }

    private var statusText: String {
        switch integration.notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "srs_notifications_allowed".localized()
        case .denied: return "srs_notifications_denied".localized()
        case .notDetermined: return "srs_notifications_not_requested".localized()
        @unknown default: return "srs_notifications_unavailable".localized()
        }
    }
}
