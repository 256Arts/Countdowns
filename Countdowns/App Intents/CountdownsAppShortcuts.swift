import AppIntents

/// Predefined phrases that let Siri and Spotlight invoke the app's intents without any setup.
struct CountdownsAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateCountdownIntent(),
            phrases: [
                "Create a countdown in \(.applicationName)",
                "Add a countdown to \(.applicationName)",
                "Start a new countdown in \(.applicationName)"
            ],
            shortTitle: "Create Countdown",
            systemImageName: "calendar.badge.plus")
        AppShortcut(
            intent: DaysUntilCountdownIntent(),
            phrases: [
                "How many days until \(\.$target) in \(.applicationName)",
                "Days until \(\.$target) in \(.applicationName)"
            ],
            shortTitle: "Days Until Event",
            systemImageName: "calendar")
        AppShortcut(
            intent: UpcomingCountdownsIntent(),
            phrases: [
                "Show my upcoming events in \(.applicationName)",
                "What's my next countdown in \(.applicationName)"
            ],
            shortTitle: "Upcoming Events",
            systemImageName: "list.bullet")
        AppShortcut(
            intent: OpenCountdownIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show \(\.$target) in \(.applicationName)"
            ],
            shortTitle: "Open Countdown",
            systemImageName: "calendar.circle")
    }
}
