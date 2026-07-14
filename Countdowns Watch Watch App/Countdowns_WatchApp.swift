import SwiftUI
import SwiftData

@main
struct Countdowns_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            UpcomingList()
        }
        .modelContainer(for: Event.self)
    }
}
