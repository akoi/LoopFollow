// LoopFollow
// StatsCalendarDayTests.swift

import Foundation
@testable import LoopFollow
import Testing

struct StatsCalendarDayTests {
    private func stockholmCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Stockholm"))
        return calendar
    }

    @Test("Autumn clock change has a 25-hour day and always advances")
    func autumnClockChange() throws {
        let calendar = try stockholmCalendar()
        let midnight = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25)))
        let day = try #require(StatsCalendarDay.bounds(containing: midnight.timeIntervalSince1970, calendar: calendar))
        #expect(day.next - day.start == 25 * 60 * 60)

        // During the repeated hour, adding 24h to midnight would remain on 25 Oct.
        let finalHour = day.next - 30 * 60
        let nearEnd = try #require(StatsCalendarDay.bounds(containing: finalHour, calendar: calendar))
        #expect(nearEnd.start == day.start)
        #expect(nearEnd.next > finalHour)

        let next = try #require(StatsCalendarDay.bounds(containing: nearEnd.next, calendar: calendar))
        #expect(next.start == day.next)
        #expect(next.next > next.start)
    }

    @Test("Spring clock change has a 23-hour day")
    func springClockChange() throws {
        let calendar = try stockholmCalendar()
        let midnight = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29)))
        let day = try #require(StatsCalendarDay.bounds(containing: midnight.timeIntervalSince1970, calendar: calendar))
        #expect(day.next - day.start == 23 * 60 * 60)
    }

    @Test("Seven statistics calendar days progress across the autumn transition")
    func sevenDayHistory() throws {
        let calendar = try stockholmCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 22)))
        var cursor = start.timeIntervalSince1970
        var seenDays = Set<TimeInterval>()

        for _ in 0 ..< 7 {
            let day = try #require(StatsCalendarDay.bounds(containing: cursor, calendar: calendar))
            #expect(day.start == cursor)
            #expect(day.next > cursor)
            #expect(seenDays.insert(day.start).inserted)
            cursor = day.next
        }
        #expect(seenDays.count == 7)
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 29)))
        #expect(cursor == expected.timeIntervalSince1970)
    }
}
