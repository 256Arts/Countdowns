import SwiftUI
import SwiftData

struct UpcomingList: View {
    
    #if targetEnvironment(simulator)
    private let allEvents: [Event] = [
        Event(dataSource: nil, title: "Halloween", colorName: .purple, icon: .symbolIcon(name: "theatermasks"), date: Calendar.current.date(byAdding: .day, value: 20, to: .now), dateIsEstimate: false),
        Event(dataSource: nil, title: "Dune: Part Two", colorName: .orange, icon: .symbolIcon(name: "film"), date: Calendar.current.date(byAdding: .day, value: 34, to: .now), dateIsEstimate: false),
        Event(dataSource: nil, title: "Star Wars Day", colorName: .yellow, icon: .symbolIcon(name: "sparkles"), date: Calendar.current.date(byAdding: .day, value: 100, to: .now), dateIsEstimate: false)
    ]
    #else
    @Query private var allEvents: [Event]
    #endif
    
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
