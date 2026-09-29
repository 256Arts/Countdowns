import Foundation
import Testing
@testable import Countdowns

struct CountdownFormatTests {

    @Test func `Raw value round-trips, largest unit first`() {
        let format = CountdownFormat(units: [.day, .week], maxMixedUnits: 2)
        #expect(format.rawValue == "2|week,day")
        #expect(CountdownFormat(rawValue: format.rawValue) == format)
    }

    @Test(arguments: ["", "2", "x|day", "2|", "2|fortnight"])
    func `Malformed raw values are rejected`(rawValue: String) {
        #expect(CountdownFormat(rawValue: rawValue) == nil)
    }

    @Test func `Mixed unit count is clamped`() {
        #expect(CountdownFormat(units: [.day], maxMixedUnits: 0).maxMixedUnits == 1)
        #expect(CountdownFormat(units: [.day], maxMixedUnits: 9).maxMixedUnits == CountdownFormat.maxMixedUnitsLimit)
    }

    @Test func `Units can never be emptied`() {
        #expect(CountdownFormat(units: [], maxMixedUnits: 1).units == [.day])

        var format = CountdownFormat(units: [.hour], maxMixedUnits: 1)
        format.units = []
        #expect(format.units == [.hour])
    }

    @Test func `Only the smallest unit sets the refresh interval`() {
        #expect(CountdownFormat(units: [.day, .second], maxMixedUnits: 2).refreshInterval == 1)
        #expect(CountdownFormat(units: [.week, .day], maxMixedUnits: 2).refreshInterval == nil)
    }

    @Test func `Zero-valued units are skipped for the next filled one`() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let format = CountdownFormat(units: [.week, .day, .hour], maxMixedUnits: 2)
        let fortnight = start.addingTimeInterval((14 * 24 + 4) * 60 * 60)
        let expected = Date.ComponentsFormatStyle(style: .wide, fields: [.week, .hour]).format(start..<fortnight)
        #expect(format.string(from: start, to: fortnight) == expected)
    }

    @Test func `An event this instant shows zero of the smallest unit`() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let format = CountdownFormat(units: [.day, .hour], maxMixedUnits: 2)
        let expected = Date.ComponentsFormatStyle(style: .wide, fields: [.hour]).format(now..<now)
        #expect(format.string(from: now, to: now) == expected)
    }

    @Test func `A day count matches the list's calendar days, not the hours left`() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 15)))
        let event = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 6)))

        let fiveDays = calendar.startOfDay(for: now)..<event
        let expected = Date.ComponentsFormatStyle(style: .wide, calendar: calendar, fields: [.day]).format(fiveDays)
        #expect(CountdownFormat.default.string(from: now, to: event, calendar: calendar) == expected)
        #expect(expected.contains("5"))
    }

    @Test func `An hour count still measures from now`() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 15)))
        let event = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 2)))

        let format = CountdownFormat(units: [.hour], maxMixedUnits: 1)
        let expected = Date.ComponentsFormatStyle(style: .wide, calendar: calendar, fields: [.hour]).format(now..<event)
        #expect(format.string(from: now, to: event, calendar: calendar) == expected)
        #expect(expected.contains("9"))
    }

}
