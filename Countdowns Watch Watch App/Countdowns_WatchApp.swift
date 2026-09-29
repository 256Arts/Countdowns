import SwiftUI
import SwiftData

@main
struct Countdowns_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            UpcomingList()
                .screenshotModeStatus()
        }
        #if targetEnvironment(simulator)
        // A simulator has no paired phone and no iCloud data to sync down, so the real store leaves
        // the list on its empty state — including the run that photographs it for the App Store.
        // The screenshot seed stands in, which also means the watch shot is of the same countdowns
        // every other platform's shots are.
        .modelContainer(ScreenshotMode.container)
        #else
        .modelContainer(for: Event.self)
        #endif
    }
}
