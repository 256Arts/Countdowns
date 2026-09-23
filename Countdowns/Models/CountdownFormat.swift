import Foundation

/// A unit of time a countdown can be spelled out in.
enum CountdownUnit: String, CaseIterable, Identifiable, Sendable {

    // Declared largest to smallest, so `allCases` is the order the units read in.
    case year, month, week, day, hour, minute, second

    var id: Self { self }

    var name: String {
        switch self {
        case .year: "Years"
        case .month: "Months"
        case .week: "Weeks"
        case .day: "Days"
        case .hour: "Hours"
        case .minute: "Minutes"
        case .second: "Seconds"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .year: .year
        case .month: .month
        case .week: .weekOfYear
        case .day: .day
        case .hour: .hour
        case .minute: .minute
        case .second: .second
        }
    }

    var field: Date.ComponentsFormatStyle.Field {
        switch self {
        case .year: .year
        case .month: .month
        case .week: .week
        case .day: .day
        case .hour: .hour
        case .minute: .minute
        case .second: .second
        }
    }

    /// How often a countdown that ends in this unit has to be redrawn to stay honest. A day or
    /// longer changes too rarely to be worth a timer.
    var refreshInterval: TimeInterval? {
        switch self {
        case .second: 1
        case .minute: 60
        case .hour: 60 * 60
        default: nil
        }
    }

}

/// How the event detail screen spells out the time until an event.
///
/// Stored as a single string so it can live behind one `@AppStorage` key: `"2|week,day"`.
struct CountdownFormat: Equatable, RawRepresentable, Sendable {

    static let `default` = CountdownFormat(units: [.day], maxMixedUnits: 1)

    /// Past four units even the short format runs out of line, so the stepper stops here.
    static let maxMixedUnitsLimit = 4

    /// The units the user wants to see. Never empty — something has to be counted.
    var units: Set<CountdownUnit> {
        didSet {
            if units.isEmpty {
                units = oldValue
            }
        }
    }

    /// The most units shown together: 2 renders 16.2 days away as "2 weeks, 2 days".
    var maxMixedUnits: Int {
        didSet {
            maxMixedUnits = Self.clamp(maxMixedUnits)
        }
    }

    init(units: Set<CountdownUnit>, maxMixedUnits: Int) {
        self.units = units.isEmpty ? [.day] : units
        self.maxMixedUnits = Self.clamp(maxMixedUnits)
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: "|", maxSplits: 1)
        guard parts.count == 2, let maxMixedUnits = Int(parts[0]) else { return nil }

        let units = parts[1].split(separator: ",").compactMap({ CountdownUnit(rawValue: String($0)) })
        guard !units.isEmpty else { return nil }

        self.init(units: Set(units), maxMixedUnits: maxMixedUnits)
    }

    var rawValue: String {
        "\(maxMixedUnits)|" + orderedUnits.map(\.rawValue).joined(separator: ",")
    }

    /// The chosen units, largest first.
    var orderedUnits: [CountdownUnit] {
        CountdownUnit.allCases.filter(units.contains)
    }

    /// How often a view showing this format has to redraw, or `nil` if it never has to.
    var refreshInterval: TimeInterval? {
        orderedUnits.last?.refreshInterval
    }

    /// Full words read best on their own, but several of them will not fit on one line, so a
    /// crowded countdown shortens: "2 weeks, 2 days" against "1y 1mo 4d 4h".
    ///
    /// This is picked from the *setting* rather than from the units a particular event happens to
    /// fill, so the countdown doesn't change its voice as the clock ticks past a unit boundary.
    private var style: Date.ComponentsFormatStyle.Style {
        switch min(units.count, maxMixedUnits) {
        case ...2: .wide
        case 3: .abbreviated
        default: .narrow
        }
    }

    func string(from start: Date, to end: Date) -> String {
        let isPast = end < start
        let range = isPast ? end..<start : start..<end
        var style = Date.ComponentsFormatStyle(style: style, fields: fields(for: range))
        style.isPositive = !isPast
        return style.format(range)
    }

    /// The largest units of `range` that have a value, at most `maxMixedUnits` of them.
    ///
    /// Units worth zero are passed over rather than counted, so a fortnight away reads
    /// "2 weeks, 4 hours" instead of spending its second slot on "0 days".
    private func fields(for range: Range<Date>) -> Set<Date.ComponentsFormatStyle.Field> {
        let ordered = orderedUnits
        guard let smallest = ordered.last else { return [] }

        let components = Calendar.autoupdatingCurrent.dateComponents(
            Set(ordered.map(\.calendarComponent)),
            from: range.lowerBound,
            to: range.upperBound)
        let filled = ordered.filter({ (components.value(for: $0.calendarComponent) ?? 0) != 0 })

        // The event is this very instant: show a zero rather than nothing at all.
        let shown = filled.isEmpty ? [smallest] : Array(filled.prefix(maxMixedUnits))
        return Set(shown.map(\.field))
    }

    private static func clamp(_ maxMixedUnits: Int) -> Int {
        min(max(maxMixedUnits, 1), maxMixedUnitsLimit)
    }

}

extension Event {

    /// The time until the event, spelled out the way the user asked for in Settings.
    func countdownString(format: CountdownFormat, now: Date = .now) -> String {
        guard let date else { return "" }

        return ((dateIsEstimate ?? false) ? "~" : "") + format.string(from: now, to: date)
    }

}
