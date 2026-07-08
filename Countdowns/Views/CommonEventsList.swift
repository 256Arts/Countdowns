//
//  CommonEventsList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-11-29.
//

import SwiftUI
import SwiftData
import StoreKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct CommonEventsList: View {
    
    let allEvents = [
        Event(dataSource: .recurrence(month: 1, day: 1, end: nil), title: "New Years", colorName: .orange, icon: .symbolIcon(name: "fireworks"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 1, day: 25, end: nil), title: "Coldest Day", colorName: .blue, icon: .symbolIcon(name: "thermometer.snowflake"), date: nil, dateIsEstimate: true),
        Event(dataSource: .recurrence(month: 2, day: 14, end: nil), title: "Valentine's Day", colorName: .red, icon: .symbolIcon(name: "heart"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 2, day: 29, end: nil), title: "Leap Day", colorName: .purple, icon: .symbolIcon(name: "arrowshape.bounce.forward"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 3, day: 10, end: nil), title: "MARIO Day", colorName: .yellow, icon: .symbolIcon(name: "questionmark.square"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 5, day: 4, end: nil), title: "Star Wars Day", colorName: .yellow, icon: .symbolIcon(name: "sparkles"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 6, day: 21, end: nil), title: "June Solstice", colorName: .yellow, icon: .symbolIcon(name: "sun.and.horizon"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 7, day: 4, end: nil), title: "4th of July", colorName: .red, icon: .symbolIcon(name: "4.square"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 7, day: 11, end: nil), title: "Hottest Day", colorName: .orange, icon: .symbolIcon(name: "thermometer.sun"), date: nil, dateIsEstimate: true),
        Event(dataSource: .recurrence(month: 10, day: 31, end: nil), title: "Halloween", colorName: .purple, icon: .symbolIcon(name: "theatermasks"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 12, day: 21, end: nil), title: "December Solstice", colorName: .blue, icon: .symbolIcon(name: "sun.and.horizon"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 12, day: 25, end: nil), title: "Christmas", colorName: .blue, icon: .symbolIcon(name: "snowflake"), date: nil, dateIsEstimate: false)
    ]
    var results: [Event] {
        if searchString.isEmpty {
            return allEvents
        } else {
            return allEvents.filter({ $0.title?.localizedCaseInsensitiveContains(searchString) ?? false })
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Query private var events: [Event]
    
    @State var searchString = ""
    
    var body: some View {
        List(results) { event in
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title ?? "")
                        .font(.title2)
                    Text(event.subtitle)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(events.contains(event) ? "Added" : "Add", systemImage: events.contains(event) ? "checkmark" : "plus") {
                    let existingEvents = events.filter({ $0 == event })
                    if existingEvents.isEmpty {
                        Task { @MainActor in
                            await event.fetch()
                            modelContext.insert(event)
                            // Increment add count and maybe ask for a review
                            if UserDefaults.standard.incrementEventAddedCount() { requestReview() }
                            #if canImport(WidgetKit)
                            WidgetCenter.shared.reloadAllTimelines()
                            #endif
                        }
                    } else {
                        for existingEvent in existingEvents {
                            modelContext.delete(existingEvent)
                            #if canImport(WidgetKit)
                            WidgetCenter.shared.reloadAllTimelines()
                            #endif
                        }
                    }
                }
                .buttonStyle(.bordered)
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .navigationTitle("Common Events")
        .searchable(text: $searchString, prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    CommonEventsList()
}
