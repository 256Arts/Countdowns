import SwiftUI
import SwiftData

struct UpcomingList: View {
    
    // A simulator used to get a hardcoded list here, because the real query has nothing to find
    // there. The app now hands the simulator a seeded store instead, so this is the one code path —
    // which is also the path the App Store screenshot is taken through.
    @Query private var allEvents: [Event]

    var body: some View {
        if allEvents.upcoming.isEmpty {
            Text("No Countdowns")
                .foregroundStyle(.secondary)
        } else {
            NavigationStack {
                List(allEvents.upcoming) { event in
                    HStack {
                        Text(event.daysUntilString)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                            .font(.title2)
                            .lineLimit(1)
                        
                        Text(event.title ?? "")
                            .lineLimit(2)
                    }
                }
                .navigationTitle("Upcoming Events")
            }
        }
    }
}

#Preview {
    UpcomingList()
}
