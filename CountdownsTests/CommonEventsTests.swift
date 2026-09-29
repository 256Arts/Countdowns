import Foundation
import Testing
@testable import Countdowns

struct CommonEventsTests {

    private func dates(_ region: Locale.Region?) -> [Event.DataSource?] {
        CommonEvents.events(for: region).map(\.dataSource)
    }

    private func recurrence(_ month: Int, _ day: Int) -> Event.DataSource {
        .recurrence(month: month, day: day, end: nil)
    }

    @Test func `A region gets its own holidays and not another's`() {
        #expect(dates(.unitedStates).contains(recurrence(7, 4)))
        #expect(!dates(.japan).contains(recurrence(7, 4)))
        #expect(dates(.japan).contains(recurrence(5, 5)))
    }

    @Test func `No region gets only the universal events`() {
        #expect(dates(nil).count == 11)
    }

    @Test func `The seasons flip south of the equator`() {
        let north = CommonEvents.events(for: .canada).filter { $0.dateIsEstimate == true }
        let south = CommonEvents.events(for: .australia).filter { $0.dateIsEstimate == true }
        #expect(north.map(\.dataSource) == [recurrence(1, 25), recurrence(7, 11)])
        #expect(south.map(\.dataSource) == [recurrence(1, 25), recurrence(7, 11)])
        #expect(north.map(\.title) == south.map(\.title).reversed())
    }

    @Test func `Events are in calendar order`() {
        let days = dates(.mexico).compactMap { source -> Int? in
            guard case let .recurrence(month, day, _) = source else { return nil }
            return month * 100 + day
        }
        #expect(days == days.sorted())
    }
}
