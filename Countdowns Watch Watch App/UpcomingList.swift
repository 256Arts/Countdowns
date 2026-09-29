import SwiftUI
import SwiftData

struct UpcomingList: View {

    // A simulator used to get a hardcoded list here, because the real query has nothing to find
    // there. The app now hands the simulator a seeded store instead, so this is the one code path —
    // which is also the path the App Store screenshot is taken through.
    @Query private var allEvents: [Event]

    var body: some View {
        NavigationStack {
            Group {
                if allEvents.upcoming.isEmpty {
                    Text("No Countdowns")
                        .foregroundStyle(.secondary)
                } else {
                    List(allEvents.upcoming) { event in
                        NavigationLink(value: event) {
                            EventRow(event: event)
                        }
                    }
                }
            }
            .navigationTitle("Upcoming Events")
            .navigationDestination(for: Event.self) { event in
                FullScreenEventView(event: event)
            }
        }
        // TMDb is not on the watch, but yearly events need no network to roll forward. Keyed on the
        // events so the ones iCloud delivers after launch are rolled forward too.
        .task(id: allEvents) {
            for event in allEvents {
                event.advanceRecurrence()
            }
        }
    }
}

#Preview {
    UpcomingList()
}
