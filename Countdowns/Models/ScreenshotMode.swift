import SwiftUI
import SwiftData
#if !os(watchOS)
import EventKit
#endif

/// Deterministic demo state for App Store screenshots, switched on by the `-screenshotMode` launch
/// argument the UI test passes.
///
/// A fresh install is empty, so a shot of the main screen would otherwise be the empty state. Seed
/// into an *in-memory* store so a run neither shows nor disturbs whatever data is on the machine
/// taking the shots.
enum ScreenshotMode {

    /// Whether this launch is a screenshot run. Read once, by the `App`'s `init`.
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMode")
    }

    /// The store the app runs against during a screenshot run.
    ///
    /// `isStoredInMemoryOnly` alone would not be enough: SwiftData still picks the CloudKit container
    /// up from the app's entitlements and syncs the developer's own countdowns down into the store
    /// being photographed, so `cloudKitDatabase: .none` is not optional here.
    @MainActor
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        guard let container = try? ModelContainer(for: Event.self, configurations: configuration) else {
            fatalError("Failed to create the screenshot ModelContainer")
        }
        seed(container.mainContext)
        return container
    }()

    /// Fills `context` with content worth photographing, and picks the countdown the Mac and iPad
    /// detail column opens on — that pane otherwise reads "No Content Selected", since nothing but
    /// an App Intent ever sets the selection.
    @MainActor
    static func seed(_ context: ModelContext) {
        let events = demoEvents()
        for event in events {
            context.insert(event)
        }
        #if !os(watchOS)
        // Not the row the walk taps, so the split view's two halves show different countdowns.
        // The watch has one screen and no selection to make.
        AppNavigation.shared.selectedEvent = events.first(where: { $0.title == "Flight to Tokyo" })
        #endif
    }

    /// The seeded countdowns, in the order `[Event].upcoming` will sort them.
    ///
    /// Dates are offsets from *today* rather than fixed calendar dates. `daysUntil` counts from
    /// `.now`, which no seed can reach, so a pinned date would make the big number on every row
    /// drift with the month the shots were taken; an offset keeps it identical on every run. The
    /// smaller date line underneath still moves, which is the part of the drift worth accepting.
    @MainActor
    private static func demoEvents() -> [Event] {
        [
            demoEvent(inDays: 2, title: "Album Release", color: .purple, icon: .symbolIcon(name: "music.note")),
            demoEvent(inDays: 5, title: "Flight to Tokyo", color: .blue, icon: .symbolIcon(name: "airplane")),
            demoEvent(inDays: 9, title: "Mom's Birthday", color: .red, icon: .symbolIcon(name: "birthday.cake"), repeatsYearly: true),
            demoEvent(inDays: 13, title: "The Chronos Project", color: .blue, icon: posterIcon),
            demoEvent(inDays: 16, title: "Marathon", color: .green, icon: .symbolIcon(name: "figure.run")),
            demoEvent(inDays: 24, title: "Console Launch", color: .orange, icon: .symbolIcon(name: "gamecontroller"), isEstimate: true),
            demoEvent(inDays: 33, title: "Concert Night", color: .yellow, icon: .symbolIcon(name: "ticket")),
            demoEvent(inDays: 47, title: "Anniversary", color: .red, icon: .symbolIcon(name: "heart"), repeatsYearly: true),
            demoEvent(inDays: 68, title: "Move-in Day", color: .orange, icon: .symbolIcon(name: "house")),
            demoEvent(inDays: 91, title: "Graduation", color: .blue, icon: .symbolIcon(name: "graduationcap"))
        ]
    }

    /// The poster for the invented film the demo movie countdown is for.
    ///
    /// Shipping a real film's poster in store artwork would be someone else's copyright, so the demo
    /// uses one for a film that does not exist. It is a *development asset* — in the build that takes
    /// the screenshots, stripped from the archive that goes to the App Store.
    ///
    /// It goes in as `.remote`, the same case a TMDB poster arrives as, so the row and the detail
    /// screen draw it through the path a real movie release goes through. A `file:` URL also means
    /// `AsyncImage` has nothing to wait on: a network fetch could still be showing its placeholder
    /// when the capture fires.
    @MainActor
    private static var posterIcon: IconResource {
        guard let url = Bundle.main.url(forResource: "ChronosProjectPoster", withExtension: "jpg") else {
            // Release builds drop development assets. Nothing but a screenshot run gets here, and a
            // countdown with the wrong icon beats one that traps.
            return .symbolIcon(name: "film")
        }
        return .remote(url)
    }

    /// One countdown, `days` from today.
    ///
    /// A yearly event keeps its seeded date: `Event.fetch()` only recomputes a recurrence that has
    /// already passed, and every seed is in the future — so the refresh the list runs on appear
    /// leaves these alone.
    @MainActor
    private static func demoEvent(inDays days: Int, title: String, color: ColorName, icon: IconResource, isEstimate: Bool = false, repeatsYearly: Bool = false) -> Event {
        let calendar = Calendar.autoupdatingCurrent
        let date = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
        let components = calendar.dateComponents([.month, .day], from: date)
        return Event(
            dataSource: repeatsYearly ? .recurrence(month: components.month!, day: components.day!, end: nil) : nil,
            title: title,
            colorName: color,
            icon: icon,
            date: date,
            dateIsEstimate: isEstimate
        )
    }

    #if !os(watchOS)
    /// The calendars the Import Calendar screen offers during a screenshot run.
    ///
    /// `EKCalendar(for:eventStore:)` builds one in memory: nothing is saved, and nothing is read, so
    /// the run never faces the Calendar permission prompt it has no way to answer. A granted run
    /// would be no better — a fresh simulator's Calendar holds one empty calendar, which makes for a
    /// picker not worth photographing.
    @MainActor
    static let demoCalendars: [EKCalendar] = {
        let store = EKEventStore()
        return [
            ("Work", CGColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)),
            ("Family", CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)),
            ("Birthdays", CGColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)),
            ("Holidays", CGColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0))
        ].map { title, color in
            let calendar = EKCalendar(for: .event, eventStore: store)
            calendar.title = title
            calendar.cgColor = color
            return calendar
        }
    }()
    #endif

    #if os(macOS)
    /// Forgets the window size and sidebar width AppKit would otherwise restore.
    ///
    /// The shots are meant to show the app's own `defaultSize`, but a saved frame wins over it. The
    /// runner clears those defaults itself — except it shells out to `defaults`, which resolves a
    /// sandboxed app's domain to its container and so deletes nothing for this app. Doing it from
    /// inside the sandbox is the only thing that reaches them, and this costs the user only the
    /// remembered window position.
    @MainActor
    static func clearSavedWindowLayout() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("NSWindow Frame") || key.hasPrefix("NSSplitView Subview Frames") {
            defaults.removeObject(forKey: key)
        }
    }
    #endif
}
