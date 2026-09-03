import SwiftUI
import SwiftData

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
        // Not the row the walk taps, so the split view's two halves show different countdowns.
        AppNavigation.shared.selectedEvent = events.first(where: { $0.title == "Flight to Tokyo" })
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
            demoEvent(inDays: 2, title: "Album Release", color: .purple, symbol: "music.note"),
            demoEvent(inDays: 5, title: "Flight to Tokyo", color: .blue, symbol: "airplane"),
            demoEvent(inDays: 9, title: "Mom's Birthday", color: .red, symbol: "birthday.cake", repeatsYearly: true),
            demoEvent(inDays: 16, title: "Marathon", color: .green, symbol: "figure.run"),
            demoEvent(inDays: 24, title: "Console Launch", color: .orange, symbol: "gamecontroller", isEstimate: true),
            demoEvent(inDays: 33, title: "Concert Night", color: .yellow, symbol: "ticket"),
            demoEvent(inDays: 47, title: "Anniversary", color: .red, symbol: "heart", repeatsYearly: true),
            demoEvent(inDays: 68, title: "Move-in Day", color: .orange, symbol: "house"),
            demoEvent(inDays: 91, title: "Graduation", color: .blue, symbol: "graduationcap")
        ]
    }

    /// One countdown, `days` from today.
    ///
    /// A yearly event keeps its seeded date: `Event.fetch()` only recomputes a recurrence that has
    /// already passed, and every seed is in the future — so the refresh the list runs on appear
    /// leaves these alone.
    @MainActor
    private static func demoEvent(inDays days: Int, title: String, color: ColorName, symbol: String, isEstimate: Bool = false, repeatsYearly: Bool = false) -> Event {
        let calendar = Calendar.autoupdatingCurrent
        let date = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
        let components = calendar.dateComponents([.month, .day], from: date)
        return Event(
            dataSource: repeatsYearly ? .recurrence(month: components.month!, day: components.day!, end: nil) : nil,
            title: title,
            colorName: color,
            icon: .symbolIcon(name: symbol),
            date: date,
            dateIsEstimate: isEstimate
        )
    }

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
