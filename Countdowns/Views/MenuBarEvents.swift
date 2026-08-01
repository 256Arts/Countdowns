#if os(macOS)
import SwiftUI
import SwiftData

/// The menu bar status item: the next event's icon beside the days remaining (eg. "12d").
struct MenuBarLabel: View {

    @Query private var allEvents: [Event]

    /// Advanced at midnight so the countdown stays accurate while the app sits in the menu bar.
    @State private var today = Calendar.autoupdatingCurrent.startOfDay(for: .now)

    private var nextEvent: Event? {
        allEvents.upcoming.first
    }

    var body: some View {
        Label {
            if let nextEvent {
                Text("\(nextEvent.daysUntilString)d")
            }
        } icon: {
            Image(systemName: nextEvent?.menuBarSymbolName ?? Symbol.defaultSymbol.rawValue)
                .symbolVariant(.fill)
        }
        .labelStyle(.titleAndIcon)
        .task(id: today) {
            guard let tomorrow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: today) else { return }

            try? await Task.sleep(for: .seconds(tomorrow.timeIntervalSinceNow))
            today = Calendar.autoupdatingCurrent.startOfDay(for: .now)
        }
    }

}

/// The menu shown when clicking the status item, listing the soonest events.
struct MenuBarEventsMenu: View {

    @Environment(\.openWindow) private var openWindow
    @Query private var allEvents: [Event]

    private var upcoming: [Event] {
        Array(allEvents.upcoming.prefix(6))
    }

    var body: some View {
        ForEach(upcoming) { event in
            Button("\(event.daysUntilString)d  \(event.title ?? "")", systemImage: event.menuBarSymbolName) {
                AppNavigation.shared.selectedEvent = event
                showMainWindow()
            }
        }
        Divider()
        Button("Open Countdowns", systemImage: "macwindow") {
            showMainWindow()
        }
        Button("Quit Countdowns", systemImage: "power") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func showMainWindow() {
        NSApplication.shared.activate()

        // A window group opens a duplicate window each time, so reuse the open one when there is one.
        if let window = NSApplication.shared.windows.first(where: \.canBecomeMain) {
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: CountdownsApp.mainWindowID)
        }
    }

}

extension Event {

    /// The menu bar renders SF Symbols only, so remote artwork falls back to its source's symbol.
    var menuBarSymbolName: String {
        if case .symbolIcon(let name) = icon {
            name
        } else if case .tvShow = dataSource {
            Symbol.tv.rawValue
        } else {
            Symbol.film.rawValue
        }
    }

}
#endif
