import Foundation

/// The yearly holidays and observances offered by Common Events, fitted to a region: the
/// universal ones, that region's own fixed-date holidays, and the seasons flipped south of the equator.
enum CommonEvents {

    /// Fresh, unsaved events in calendar order — new instances on every call, since each insert
    /// into a context takes ownership of one.
    static func events(for region: Locale.Region? = Locale.current.region) -> [Event] {
        let isSouthern = region.map { southernHemisphere.contains($0.identifier) } ?? false
        let holidays = universal(isSouthern: isSouthern) + (region.flatMap { regional[$0.identifier] } ?? [])
        return holidays
            .sorted { ($0.month, $0.day) < ($1.month, $1.day) }
            .map(\.event)
    }

    private struct Holiday {
        let title: String
        let month: Int
        let day: Int
        let color: ColorName
        let symbol: String
        var isEstimate = false

        var event: Event {
            Event(dataSource: .recurrence(month: month, day: day, end: nil), title: title, colorName: color, icon: .symbolIcon(name: symbol), date: nil, dateIsEstimate: isEstimate)
        }
    }

    private static let southernHemisphere: Set<String> = ["AU", "NZ", "ZA", "AR", "BR", "CL"]

    private static func universal(isSouthern: Bool) -> [Holiday] {
        let (hottest, coldest) = isSouthern ? ((1, 25), (7, 11)) : ((7, 11), (1, 25))
        return [
            Holiday(title: String(localized: "New Years"), month: 1, day: 1, color: .orange, symbol: "fireworks"),
            Holiday(title: String(localized: "Coldest Day"), month: coldest.0, day: coldest.1, color: .blue, symbol: "thermometer.snowflake", isEstimate: true),
            Holiday(title: String(localized: "Valentine's Day"), month: 2, day: 14, color: .red, symbol: "heart"),
            Holiday(title: String(localized: "Leap Day"), month: 2, day: 29, color: .purple, symbol: "arrowshape.bounce.forward"),
            Holiday(title: String(localized: "MARIO Day"), month: 3, day: 10, color: .yellow, symbol: "questionmark.square"),
            Holiday(title: String(localized: "Star Wars Day"), month: 5, day: 4, color: .yellow, symbol: "sparkles"),
            Holiday(title: String(localized: "June Solstice"), month: 6, day: 21, color: .yellow, symbol: "sun.and.horizon"),
            Holiday(title: String(localized: "Hottest Day"), month: hottest.0, day: hottest.1, color: .orange, symbol: "thermometer.sun", isEstimate: true),
            Holiday(title: String(localized: "Halloween"), month: 10, day: 31, color: .purple, symbol: "theatermasks"),
            Holiday(title: String(localized: "December Solstice"), month: 12, day: 21, color: .blue, symbol: "sun.and.horizon"),
            Holiday(title: String(localized: "Christmas"), month: 12, day: 25, color: .blue, symbol: "snowflake")
        ]
    }

    /// Fixed-date holidays by region identifier. Movable ones (Easter, Thanksgiving, Lunar New Year)
    /// need a recurrence rule `DataSource` doesn't have.
    private static var regional: [String: [Holiday]] {
        [
            "US": [
                Holiday(title: String(localized: "4th of July", comment: "US Independence Day"), month: 7, day: 4, color: .red, symbol: "4.square")
            ],
            "CA": [
                Holiday(title: String(localized: "Canada Day"), month: 7, day: 1, color: .red, symbol: "leaf")
            ],
            "GB": [
                Holiday(title: String(localized: "Bonfire Night", comment: "Guy Fawkes Night, UK, November 5"), month: 11, day: 5, color: .orange, symbol: "flame")
            ],
            "FR": [
                Holiday(title: String(localized: "Bastille Day", comment: "French National Day, July 14"), month: 7, day: 14, color: .blue, symbol: "flag")
            ],
            "DE": [
                Holiday(title: String(localized: "German Unity Day", comment: "Tag der Deutschen Einheit, October 3"), month: 10, day: 3, color: .yellow, symbol: "flag")
            ],
            "JP": [
                Holiday(title: String(localized: "Children's Day", comment: "Japanese holiday, May 5"), month: 5, day: 5, color: .blue, symbol: "fish"),
                Holiday(title: String(localized: "Culture Day", comment: "Japanese holiday, November 3"), month: 11, day: 3, color: .purple, symbol: "paintpalette")
            ],
            "CN": [
                Holiday(title: String(localized: "National Day", comment: "People's Republic of China National Day, October 1"), month: 10, day: 1, color: .red, symbol: "flag")
            ],
            "MX": [
                Holiday(title: String(localized: "Independence Day", comment: "Mexican Independence Day, September 16"), month: 9, day: 16, color: .green, symbol: "flag"),
                Holiday(title: String(localized: "Day of the Dead", comment: "Día de Muertos, Mexico, November 2"), month: 11, day: 2, color: .orange, symbol: "camera.macro")
            ]
        ]
    }
}
