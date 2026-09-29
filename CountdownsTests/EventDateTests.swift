import Foundation
import Testing
@testable import Countdowns

/// A fixed zone with daylight saving, so the DST cases mean the same thing on every machine.
private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Toronto")!
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, in calendar: Calendar = calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

private func makeEvent(_ date: Date?, title: String = "Event") -> Event {
    Event(dataSource: nil, title: title, colorName: nil, icon: nil, date: date, dateIsEstimate: false)
}

struct RecurrenceTests {

    @Test func `Later this year stays in this year`() {
        let next = Event.nextOccurrence(month: 12, day: 25, end: nil, after: date(2026, 9, 26), calendar: calendar)
        #expect(next == date(2026, 12, 25))
    }

    @Test func `The day itself rolls to next year`() {
        let next = Event.nextOccurrence(month: 9, day: 26, end: nil, after: date(2026, 9, 26, hour: 15), calendar: calendar)
        #expect(next == date(2027, 9, 26))
    }

    @Test func `Earlier this year rolls to next year`() {
        let next = Event.nextOccurrence(month: 1, day: 1, end: nil, after: date(2026, 9, 26), calendar: calendar)
        #expect(next == date(2027, 1, 1))
    }

    @Test func `An occurrence on or after the end date is dropped`() {
        #expect(Event.nextOccurrence(month: 12, day: 25, end: date(2026, 12, 25), after: date(2026, 9, 26), calendar: calendar) == nil)
        #expect(Event.nextOccurrence(month: 12, day: 25, end: date(2026, 12, 26), after: date(2026, 9, 26), calendar: calendar) == date(2026, 12, 25))
    }

    @Test(arguments: [
        (date(2026, 9, 26), date(2028, 2, 29)),
        (date(2028, 2, 28), date(2028, 2, 29)),
        (date(2028, 2, 29), date(2032, 2, 29)),
        (date(2096, 3, 1), date(2104, 2, 29)), // 2100 is not a leap year
        (date(2099, 1, 1), date(2104, 2, 29)),
        (date(2396, 3, 1), date(2400, 2, 29)), // 2400 is
    ])
    func `Leap day skips to the next leap year`(now: Date, expected: Date) {
        #expect(Event.nextOccurrence(month: 2, day: 29, end: nil, after: now, calendar: calendar) == expected)
    }

    @Test func `A passed yearly event advances, an upcoming one stays`() {
        let passed = Event(dataSource: .recurrence(month: 9, day: 20, end: nil), title: "Passed", colorName: nil, icon: nil, date: date(2026, 9, 20), dateIsEstimate: false)
        passed.advanceRecurrence(from: date(2026, 9, 26), calendar: calendar)
        #expect(passed.date == date(2027, 9, 20))

        let today = Event(dataSource: .recurrence(month: 9, day: 26, end: nil), title: "Today", colorName: nil, icon: nil, date: date(2026, 9, 26), dateIsEstimate: false)
        today.advanceRecurrence(from: date(2026, 9, 26, hour: 15), calendar: calendar)
        #expect(today.date == date(2026, 9, 26))
    }

    @Test func `Advancing leaves non-recurring events alone`() {
        let single = makeEvent(date(2026, 9, 20))
        single.advanceRecurrence(from: date(2026, 9, 26), calendar: calendar)
        #expect(single.date == date(2026, 9, 20))
    }

}

struct DaysUntilTests {

    @Test func `Counts calendar days, not 24-hour periods`() {
        #expect(makeEvent(date(2026, 9, 27)).daysUntil(from: date(2026, 9, 26, hour: 23), calendar: calendar) == 1)
        #expect(makeEvent(date(2026, 9, 26)).daysUntil(from: date(2026, 9, 26, hour: 23), calendar: calendar) == 0)
        #expect(makeEvent(date(2026, 9, 25)).daysUntil(from: date(2026, 9, 26), calendar: calendar) == -1)
    }

    @Test func `Spring forward is still one day`() {
        // Clocks jump 2:00 → 3:00 on 2026-03-08 in Toronto
        #expect(makeEvent(date(2026, 3, 9)).daysUntil(from: date(2026, 3, 7, hour: 22), calendar: calendar) == 2)
        #expect(makeEvent(date(2026, 3, 9)).daysUntil(from: date(2026, 3, 8, hour: 12), calendar: calendar) == 1)
    }

    @Test func `Fall back is still one day`() {
        // Clocks repeat 1:00 → 2:00 on 2026-11-01 in Toronto
        #expect(makeEvent(date(2026, 11, 2)).daysUntil(from: date(2026, 10, 31, hour: 22), calendar: calendar) == 2)
        #expect(makeEvent(date(2026, 11, 2)).daysUntil(from: date(2026, 11, 1, hour: 12), calendar: calendar) == 1)
    }

    @Test func `No date has no count`() {
        #expect(makeEvent(nil).daysUntil(from: .now, calendar: calendar) == nil)
    }

}

/// `relevanceScore` and `upcoming` read the user's calendar, so these build dates in it too.
struct RelevanceTests {

    let now = date(2026, 9, 26, hour: 12, in: .autoupdatingCurrent)

    func event(inDays days: Int?, title: String = "Event") -> Event {
        let today = Calendar.autoupdatingCurrent.startOfDay(for: now)
        return makeEvent(days.map({ Calendar.autoupdatingCurrent.date(byAdding: .day, value: $0, to: today)! }), title: title)
    }

    @Test(arguments: [(0, 31), (1, 30), (15, 16), (30, 1), (31, 1), (400, 1), (-1, 0), (-30, 0)])
    func `Score falls from 31 today to a floor of 1`(days: Int, score: Int) {
        #expect(event(inDays: days).relevanceScore(from: now) == score)
    }

    @Test func `No date scores zero`() {
        #expect(event(inDays: nil).relevanceScore(from: now) == 0)
    }

    @Test func `Upcoming drops past and undated events and sorts soonest first`() {
        let events = [
            event(inDays: 90, title: "Far"),
            event(inDays: -3, title: "Past"),
            event(inDays: nil, title: "Undated"),
            event(inDays: 2, title: "Soon"),
            event(inDays: 0, title: "Today"),
            event(inDays: 40, title: "Later"),
        ]
        #expect(events.upcoming(from: now).map(\.title) == ["Today", "Soon", "Later", "Far"])
    }

}

struct PassedForGoodTests {

    private let now = date(2026, 9, 26, hour: 15)

    @Test func `A one-off event is kept on its day and deleted the day after`() {
        #expect(!makeEvent(date(2026, 9, 26)).hasPassedForGood(from: now, calendar: calendar))
        #expect(makeEvent(date(2026, 9, 25)).hasPassedForGood(from: now, calendar: calendar))
        #expect(!makeEvent(nil).hasPassedForGood(from: now, calendar: calendar))
    }

    @Test func `A released movie is deleted, an estimated one waits on TMDB`() {
        let released = Event(dataSource: .movie(id: 1), title: "Released", colorName: nil, icon: nil, date: date(2026, 9, 25), dateIsEstimate: false)
        let estimated = Event(dataSource: .movie(id: 2), title: "Estimated", colorName: nil, icon: nil, date: date(2026, 9, 25), dateIsEstimate: true)
        #expect(released.hasPassedForGood(from: now, calendar: calendar))
        #expect(!estimated.hasPassedForGood(from: now, calendar: calendar))
    }

    @Test func `TV shows and calendar events are never deleted here`() {
        let show = Event(dataSource: .tvShow(id: 1), title: "Show", colorName: nil, icon: nil, date: date(2020, 1, 1), dateIsEstimate: false)
        let calendarEvent = Event(dataSource: .calendar(id: "a"), title: "Meeting", colorName: nil, icon: nil, date: date(2020, 1, 1), dateIsEstimate: false)
        #expect(!show.hasPassedForGood(from: now, calendar: calendar))
        #expect(!calendarEvent.hasPassedForGood(from: now, calendar: calendar))
    }

    @Test func `A yearly event is deleted only once its end leaves no next occurrence`() {
        let ended = Event(dataSource: .recurrence(month: 9, day: 20, end: date(2027, 1, 1)), title: "Ended", colorName: nil, icon: nil, date: nil, dateIsEstimate: false)
        let lastToday = Event(dataSource: .recurrence(month: 9, day: 26, end: date(2027, 1, 1)), title: "Last", colorName: nil, icon: nil, date: date(2026, 9, 26), dateIsEstimate: false)
        let ongoing = Event(dataSource: .recurrence(month: 9, day: 20, end: nil), title: "Ongoing", colorName: nil, icon: nil, date: date(2026, 9, 20), dateIsEstimate: false)
        #expect(ended.hasPassedForGood(from: now, calendar: calendar))
        #expect(!lastToday.hasPassedForGood(from: now, calendar: calendar))
        #expect(!ongoing.hasPassedForGood(from: now, calendar: calendar))
    }

}
