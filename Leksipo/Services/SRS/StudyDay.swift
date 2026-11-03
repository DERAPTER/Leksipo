import Foundation

/// Учебный день — гражданская дата григорианского календаря в текущей зоне.
/// Исторический dateKey сохраняется при переезде; абсолютные SRS-даты
/// интерпретируются в зоне устройства при построении очереди.
enum StudyDay {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    static func key(for date: Date, calendar: Calendar = calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func date(for key: String, calendar: Calendar = calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: key), self.key(for: date, calendar: calendar) == key else { return nil }
        return date
    }

    static func end(of date: Date, calendar: Calendar = calendar) -> Date {
        calendar.dateInterval(of: .day, for: date)?.end ?? date
    }
}
