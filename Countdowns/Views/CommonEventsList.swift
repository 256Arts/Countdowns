//
//  CommonEventsList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-11-29.
//

import SwiftUI
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

struct CommonEventsList: View {
    
    let allEvents = [
        Event(dataSource: .recurrence(month: 1, day: 1, end: nil), title: "New Years", colorHEX: nil, icon: .symbolIcon(name: "sparkles"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 1, day: 25, end: nil), title: "Coldest Day", colorHEX: nil, icon: .symbolIcon(name: "thermometer.snowflake"), date: nil, dateIsEstimate: true),
        Event(dataSource: .recurrence(month: 2, day: 14, end: nil), title: "Valentine's Day", colorHEX: nil, icon: .symbolIcon(name: "heart"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 2, day: 29, end: nil), title: "Leap Day", colorHEX: nil, icon: .symbolIcon(name: "arrowshape.bounce.forward"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 3, day: 10, end: nil), title: "MARIO Day", colorHEX: nil, icon: .symbolIcon(name: "questionmark.square"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 5, day: 4, end: nil), title: "Star Wars Day", colorHEX: nil, icon: .symbolIcon(name: "sparkles"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 6, day: 21, end: nil), title: "June Solstice", colorHEX: nil, icon: .symbolIcon(name: "sun.and.horizon"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 7, day: 4, end: nil), title: "4th of July", colorHEX: nil, icon: .symbolIcon(name: "4.square"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 7, day: 11, end: nil), title: "Hottest Day", colorHEX: nil, icon: .symbolIcon(name: "thermometer.sun"), date: nil, dateIsEstimate: true),
        Event(dataSource: .recurrence(month: 10, day: 31, end: nil), title: "Halloween", colorHEX: nil, icon: .symbolIcon(name: "theatermasks"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 12, day: 21, end: nil), title: "December Solstice", colorHEX: nil, icon: .symbolIcon(name: "sun.and.horizon"), date: nil, dateIsEstimate: false),
        Event(dataSource: .recurrence(month: 12, day: 25, end: nil), title: "Christmas", colorHEX: nil, icon: .symbolIcon(name: "snowflake"), date: nil, dateIsEstimate: false)
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
    @Query private var events: [Event]
    
    @State var searchString = ""
    
    var body: some View {
        List(results) { event in
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title ?? "")
                        .font(.title2)
                    Text(event.subtitle)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    let existingEvents = events.filter({ $0 == event })
                    if existingEvents.isEmpty {
                        Task { @MainActor in
                            await event.fetch()
                            modelContext.insert(event)
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
                } label: {
                    Image(systemName: events.contains(event) ? "checkmark" : "plus")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .fontWeight(.bold)
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .navigationTitle("Common Events")
        .searchable(text: $searchString, prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    CommonEventsList()
}
