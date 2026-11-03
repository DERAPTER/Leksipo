import Foundation

@MainActor
enum SRSWidgetSnapshotWriter {
    static func make(cardRepository: CardRepository, statsRepository: StatsRepository,
                     newCardsLimit: Int, date: Date, calendar: Calendar = StudyDay.calendar) throws -> SRSWidgetSnapshot {
        let overview = try cardRepository.srsOverview(on: date, newCardsLimit: newCardsLimit)
        let streak = try statsRepository.currentSRSStreak(on: date)
        return SRSWidgetSnapshot(
            dueToday: overview.dueToday, srsStreak: streak,
            nextReviewDate: overview.nextReviewDate, nextReviewCount: overview.nextReviewCount,
            updatedAt: date, validUntil: min(StudyDay.end(of: date, calendar: calendar), date.addingTimeInterval(6 * 3600)),
            timeZoneID: calendar.timeZone.identifier
        )
    }
}
