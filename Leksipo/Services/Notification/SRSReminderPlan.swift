import Foundation

struct SRSReminder: Equatable {
    let identifier: String
    let components: DateComponents
    let title: String
    let body: String
}

/// Без ответов в приложении назначения остаются актуальными на последующие дни.
/// Ограничиваем число запросов, оставляя место другим системным уведомлениям.
enum SRSReminderPlan {
    static let capacity = 32
    static let identifiers = ["daily_srs_reminder"] + (0..<capacity).map { "daily_srs_reminder.\($0)" }

    static func make(firstDueDay: Date?, now: Date, hour: Int, minute: Int,
                     title: String, body: String, calendar: Calendar = StudyDay.calendar) -> [SRSReminder] {
        guard let firstDueDay else { return [] }
        var day = max(calendar.startOfDay(for: now), calendar.startOfDay(for: firstDueDay))
        var result: [SRSReminder] = []
        // Первое время могло уже пройти; остальные даты остаются полными датами,
        // а timeZone не фиксируется — системный триггер следует местному времени.
        for _ in 0...capacity {
            if let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), fire > now {
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                result.append(SRSReminder(identifier: "daily_srs_reminder.\(result.count)", components: components, title: title, body: body))
                if result.count == capacity { break }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }
}
