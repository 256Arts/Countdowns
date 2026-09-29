import Foundation
import SwiftData

@Model
final class Event {
    
    /// Used to update the event date
    enum DataSource: Equatable, Codable {
        case recurrence(month: Int, day: Int, end: Date?)
        case movie(id: Int)
        case tvShow(id: Int)
        case calendar(id: String)
    }
    
    var dataSource: DataSource?
    var title: String? //= ""
    var colorName: ColorName?
    var iconURL: String?
    
    var date: Date?
    var dateIsEstimate: Bool? //= false
    /// For `.calendar` events: the `CalendarOccurrence.id` this event mirrors
    var calendarItemID: String?
    
    init(dataSource: DataSource?, title: String, colorName: ColorName?, icon: IconResource?, date: Date?, dateIsEstimate: Bool?) {
        self.dataSource = dataSource
        self.title = title
        self.colorName = colorName
        self.date = date
        self.dateIsEstimate = dateIsEstimate
        self.icon = icon
    }
    
    /// DO NOT USE - For SwiftData only (is this needed?)
    init(dataSource: DataSource?, title: String, colorName: ColorName?, iconURL: String?, date: Date?, dateIsEstimate: Bool?) {
        self.dataSource = dataSource
        self.title = title
        self.colorName = colorName
        self.iconURL = iconURL
        self.date = date
        self.dateIsEstimate = dateIsEstimate
    }
    
    @Transient
    var preloadedIconData: Data?
    
    @Transient
    var icon: IconResource? {
        get {
            if let preloadedIconData {
                return .preloaded(preloadedIconData)
            } else {
                let urlString = iconURL ?? Symbol.defaultSymbol.rawValue
                if urlString.contains("/"), let url = URL(string: urlString) {
                    return .remote(url)
                } else {
                    return .symbolIcon(name: urlString)
                }
            }
        }
        set {
            switch newValue {
            case .preloaded(let data):
                preloadedIconData = data
            case .remote(let url):
                iconURL = url.absoluteString
            case .symbolIcon(name: let name):
                iconURL = name
            case nil:
                preloadedIconData = nil
                iconURL = nil
            }
        }
    }
    
    @Transient
    var subtitle: LocalizedStringResource {
        switch dataSource {
        case .recurrence(let month, let day, _):
            if month == 2, day == 29 {
                "Every ~4 years on \(DateFormatter().monthSymbols[month-1]) \(day)"
            } else {
                "Yearly on \(DateFormatter().monthSymbols[month-1]) \(day)"
            }
        case .movie, .tvShow:
            "From TMDB"
        case .calendar:
            "From Calendar"
        case nil:
            "Single Event"
        }
    }
    
    @Transient
    var daysUntil: Int? {
        daysUntil(from: .now)
    }
    
    func daysUntil(from now: Date, calendar: Calendar = .autoupdatingCurrent) -> Int? {
        if let date {
            return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: date).day
        } else {
            return nil
        }
    }
    
    @Transient
    var daysUntilString: String {
        if let daysUntil {
            ((dateIsEstimate ?? false) ? "~" : "") + String(daysUntil)
        } else {
            ""
        }
    }
    
    /// Whether the estimated date will be replaced by a server value when it becomes available
    @Transient
    var isTemporaryEstimate: Bool {
        guard dateIsEstimate == true else { return false }
        
        return switch dataSource {
        case .recurrence:
            false
        default:
            true
        }
    }
    
    @Transient
    var relevanceScore: Int {
        relevanceScore(from: .now)
    }
    
    func relevanceScore(from now: Date) -> Int {
        // Note: Do not sort by this value, since 30+ days would all share the same sort position
        
        // -1 days away = 0 score
        //  0 days away = 31 score
        //  1 days away = 30 score
        // 30 days away = 1 score
        // 31 days away = 1 score
        return if let daysUntil = daysUntil(from: now), 0 <= daysUntil {
            max(1, 31 - daysUntil)
        } else {
            0
        }
    }
    
    @Transient
    var isEditable: Bool {
        switch dataSource {
        case .movie, .tvShow:
            false
        default:
            true
        }
    }
    
    /// The poster `preloadImage(large:)` downloads into `preloadedIconData`, or `nil` for a symbol icon.
    func preloadURL(large: Bool) -> URL? {
        guard case .remote(let url) = icon else { return nil }
        return url.poster(size: large ? .large : .thumbnail)
    }
    
    @MainActor
    func preloadImage(large: Bool) async throws {
        if let url = preloadURL(large: large) {
            preloadedIconData = try await URLSession.shared.data(from: url).0
        }
    }
    
    /// The next `month`/`day` after today — Feb 29 skips to the next leap year — or `nil` if it falls on or after `end`.
    static func nextOccurrence(month: Int, day: Int, end: Date?, after now: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        let next = calendar.nextDate(after: calendar.startOfDay(for: now), matching: DateComponents(month: month, day: day), matchingPolicy: .strict)
        guard let next, next < (end ?? .distantFuture) else { return nil }
        return next
    }
    
    /// Rolls a yearly event that has passed forward to its next occurrence. Needs no network, so unlike `fetch()` it runs on watchOS too.
    func advanceRecurrence(from now: Date = .now, calendar: Calendar = .autoupdatingCurrent) {
        guard case .recurrence(let month, let day, let endDate) = dataSource else { return }
        if let daysUntil = daysUntil(from: now, calendar: calendar) {
            guard daysUntil < 0 else { return }
        }
        
        self.date = Self.nextOccurrence(month: month, day: day, end: endDate, after: now, calendar: calendar)
    }
    
    /// Whether the event is behind us with nothing left to count down to, so it can be deleted. TV shows can always
    /// get another season, calendar events are pruned by `regenerateCalendarEvents`, and an estimated release date
    /// still waits on TMDB.
    func hasPassedForGood(from now: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        switch dataSource {
        case nil:
            return (daysUntil(from: now, calendar: calendar) ?? 0) < 0
        case .movie:
            return dateIsEstimate != true && (daysUntil(from: now, calendar: calendar) ?? 0) < 0
        case .recurrence(let month, let day, let end):
            if let daysUntil = daysUntil(from: now, calendar: calendar), 0 <= daysUntil { return false }
            return Self.nextOccurrence(month: month, day: day, end: end, after: now, calendar: calendar) == nil
        case .tvShow, .calendar:
            return false
        }
    }

    #if !os(watchOS)
    /// A TMDB release date and poster, looked up by `DataSource` alone so lookups can run side by side off the main actor.
    struct Release: Sendable {
        let date: Date
        /// The poster's URL, or the fallback symbol's name.
        let iconURL: String
    }
    
    /// The release for a movie or TV show, or `nil` for any other source. Calendar events are not
    /// looked up one by one — regenerating the whole calendar is safer.
    static func fetchRelease(for dataSource: DataSource?) async -> Release? {
        let (result, symbol): ((Date?, URL?)?, String) = switch dataSource {
        case .movie(let id): (try? await MediaDatabase.shared.fetchMovieReleaseDate(id: id), "film")
        case .tvShow(let id): (try? await MediaDatabase.shared.fetchTVShowReleaseDate(id: id), "tv")
        default: (nil, "")
        }
        guard let result, let date = result.0 else { return nil }
        return Release(date: date, iconURL: result.1?.absoluteString ?? symbol)
    }
    
    /// Brings this one event's date up to date. `UpcomingList.refreshEvents()` does the same for every event at once.
    @MainActor
    func fetch() async {
        advanceRecurrence()
        if let release = await Self.fetchRelease(for: dataSource) {
            apply(release)
        }
    }
    
    func apply(_ release: Release) {
        iconURL = release.iconURL
        date = release.date
        dateIsEstimate = false
    }
    #endif
    
    /// Whether both events describe the same occasion, e.g. to tell if a common event is already added. Not `==`, which is model identity.
    func isSameSource(as other: Event) -> Bool {
        if let dataSource {
            dataSource == other.dataSource && title == other.title
        } else {
            title == other.title && date == other.date
        }
    }
}

extension [Event] {
    var upcoming: [Event] {
        upcoming(from: .now)
    }
    
    func upcoming(from now: Date) -> [Event] {
        filter({ $0.relevanceScore(from: now) > 0 }).sorted(by: { $0.daysUntil(from: now) ?? .max < $1.daysUntil(from: now) ?? .max })
    }
}
