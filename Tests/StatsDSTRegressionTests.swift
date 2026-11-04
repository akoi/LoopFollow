// LoopFollow
// StatsDSTRegressionTests.swift

import Foundation
@testable import LoopFollow
import ShareClient
import Testing

@Suite(.serialized)
@MainActor
struct StatsDSTRegressionTests {
    @Test("Statistics completes across Stockholm clock changes", arguments: [
        (month: 10, day: 25, days: 1, hours: 25.0),
        (month: 3, day: 29, days: 1, hours: 23.0),
        (month: 10, day: 22, days: 7, hours: 169.0),
    ])
    func clockChange(period: (month: Int, day: Int, days: Int, hours: Double)) throws {
        let storage = Storage.shared
        let savedEnabled = storage.graphTimeZoneEnabled.value
        let savedZone = storage.graphTimeZoneIdentifier.value
        defer {
            storage.graphTimeZoneEnabled.value = savedEnabled
            storage.graphTimeZoneIdentifier.value = savedZone
        }
        storage.graphTimeZoneEnabled.value = true
        storage.graphTimeZoneIdentifier.value = "Europe/Stockholm"
        let calendar = dateTimeUtils.displayCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: period.month, day: period.day)))
        let end = try #require(calendar.date(byAdding: .day, value: period.days, to: start))
        #expect(end.timeIntervalSince(start) / 3600 == period.hours)

        // A fresh, unloaded controller supplies fictional data without starting
        // its network tasks or touching the app's shared data pipeline.
        let controller = MainViewController()
        controller.basalProfile = [.init(value: 1, time: "00:00", timeAsSeconds: 0)]
        controller.statsBGData = [ShareGlucoseData(sgv: 100, date: start.timeIntervalSince1970, direction: nil)]
        let service = StatsDataService(mainViewController: controller)
        service.updateDateRange(start: start, end: end.addingTimeInterval(-1))
        #expect(service.daysToAnalyze == period.days)

        for offset in 0 ..< period.days {
            let day = try #require(calendar.date(byAdding: .day, value: offset, to: start))
            let next = try #require(calendar.date(byAdding: .day, value: 1, to: day))
            service.tempBasalEntries.append(.init(
                rate: 2,
                startTime: day.timeIntervalSince1970,
                durationMinutes: next.timeIntervalSince(day) / 60
            ))
        }

        let model = SimpleStatsViewModel(dataService: service)
        model.calculateStats()
        // The last second is excluded by the inclusive date-range convention.
        let expectedAdjustment = (period.hours - 1.0 / 3600) / Double(period.days)
        let adjustment = try #require(model.totalPositiveBasal)
        #expect(abs(adjustment - expectedAdjustment) < 0.000001)
        #expect(model.programmedBasal == 24)
    }
}
