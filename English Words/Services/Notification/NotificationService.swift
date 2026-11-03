import Foundation
import UserNotifications

@MainActor
protocol SRSNotificationClient {
    func authorization() async -> UNAuthorizationStatus
    func requestPermission() async throws -> Bool
    func add(_ reminder: SRSReminder) async throws
    func remove(identifiers: [String])
}

@MainActor
final class SystemSRSNotificationClient: SRSNotificationClient {
    private let center = UNUserNotificationCenter.current()

    func authorization() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }
    func requestPermission() async throws -> Bool { try await center.requestAuthorization(options: [.alert, .sound, .badge]) }
    func remove(identifiers: [String]) { center.removePendingNotificationRequests(withIdentifiers: identifiers) }

    func add(_ reminder: SRSReminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.userInfo = ["route": "srs"]
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
    }
}

@MainActor
@Observable
final class NotificationService {
    private let client: SRSNotificationClient
    private var revision = 0
    private var desired: [SRSReminder] = []
    private var worker: Task<Void, Never>?
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var errorMessage: String?

    init(client: SRSNotificationClient) { self.client = client }

    func refreshAuthorization() async {
        authorizationStatus = await client.authorization()
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await client.requestPermission()
            await refreshAuthorization()
            errorMessage = nil
            return granted
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func replace(with reminders: [SRSReminder]) {
        revision += 1
        desired = reminders
        // Отмена видна сразу; незавершённый add будет удалён после его callback.
        if reminders.isEmpty { client.remove(identifiers: SRSReminderPlan.identifiers) }
        guard worker == nil else { return }
        // Задача ограничена одним набором запросов. После cancel/replace она
        // дожидается уже начатого add и удаляет его устаревший результат.
        worker = Task { [weak self] in await self?.drain() }
    }

    func waitUntilIdle() async { await worker?.value }

    private func drain() async {
        defer { worker = nil }
        while !Task.isCancelled {
            let version = revision
            let target = desired
            let status = await client.authorization()
            authorizationStatus = status
            guard version == revision else { continue }
            client.remove(identifiers: SRSReminderPlan.identifiers)
            errorMessage = nil
            if status == .authorized || status == .provisional || status == .ephemeral {
                for reminder in target {
                    guard version == revision, !Task.isCancelled else { break }
                    do { try await client.add(reminder) }
                    catch { if version == revision { errorMessage = error.localizedDescription } }
                    if version != revision || Task.isCancelled {
                        client.remove(identifiers: [reminder.identifier])
                        break
                    }
                }
            }
            if version == revision { return }
        }
    }
}
