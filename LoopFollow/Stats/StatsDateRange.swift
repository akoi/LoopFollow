// LoopFollow
// StatsDateRange.swift

import Foundation

enum StatsDateRange {
    /// Returns start/end dates for the last complete N-day period.
    /// End is 23:59:59 of yesterday; start is 00:00:00 of the day N days back.
    static func lastComplete(days: Int) -> (start: Date, end: Date) {
        let calendar = dateTimeUtils.displayCalendar()
        let startOfToday = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .second, value: -1, to: startOfToday) ?? Date()
        let endDayStart = calendar.startOfDay(for: end)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: endDayStart) ?? endDayStart
        return (start: calendar.startOfDay(for: start), end: end)
    }
}


/// Calendar-day progression for historical stats; a local day can be 23 or 25 hours.
/// Shared by basal gap reconstruction and temp-basal adjustment calculations.
enum StatsCalendarDay {
    static func bounds(containing timestamp: TimeInterval, calendar: Calendar) -> (start: TimeInterval, next: TimeInterval)? {
        let dayStart = calendar.startOfDay(for: Date(timeIntervalSince1970: timestamp))
        guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return nil
        }
        return (start: dayStart.timeIntervalSince1970, next: nextDayStart.timeIntervalSince1970)
    }
}
