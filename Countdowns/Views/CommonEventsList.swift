//
//  CommonEventsList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-11-29.
//

import SwiftUI

struct CommonEventsList: View {
    
    let allEvents = [
        Event(id: "new years", dataSource: .recurrence(month: 1, day: 1, end: nil), title: "New Years", colorHEX: nil, icon: .symbolIcon(name: "sparkles"), date: nil, dateIsEstimate: false),
        Event(id: "valentines", dataSource: .recurrence(month: 2, day: 14, end: nil), title: "Valentine's Day", colorHEX: nil, icon: .symbolIcon(name: "heart"), date: nil, dateIsEstimate: false),
        Event(id: "leap day", dataSource: .recurrence(month: 2, day: 29, end: nil), title: "Leap Day", colorHEX: nil, icon: .symbolIcon(name: "arrowshape.bounce.forward"), date: nil, dateIsEstimate: false),
        Event(id: "mario day", dataSource: .recurrence(month: 3, day: 10, end: nil), title: "MARIO Day", colorHEX: nil, icon: .symbolIcon(name: "questionmark.square"), date: nil, dateIsEstimate: false),
        Event(id: "star wars", dataSource: .recurrence(month: 5, day: 4, end: nil), title: "Star Wars Day", colorHEX: nil, icon: .symbolIcon(name: "sparkles"), date: nil, dateIsEstimate: false),
        Event(id: "june solstice", dataSource: .recurrence(month: 6, day: 21, end: nil), title: "June Solstice", colorHEX: nil, icon: .symbolIcon(name: "sun.and.horizon"), date: nil, dateIsEstimate: false),
        Event(id: "4th of july", dataSource: .recurrence(month: 7, day: 4, end: nil), title: "4th of July", colorHEX: nil, icon: .symbolIcon(name: "4.square"), date: nil, dateIsEstimate: false),
        Event(id: "halloween", dataSource: .recurrence(month: 10, day: 31, end: nil), title: "Halloween", colorHEX: nil, icon: .symbolIcon(name: "theatermasks"), date: nil, dateIsEstimate: false),
        Event(id: "december solstice", dataSource: .recurrence(month: 12, day: 21, end: nil), title: "December Solstice", colorHEX: nil, icon: .symbolIcon(name: "sun.and.horizon"), date: nil, dateIsEstimate: false),
        Event(id: "chirstmas", dataSource: .recurrence(month: 12, day: 25, end: nil), title: "Christmas", colorHEX: nil, icon: .symbolIcon(name: "snowflake"), date: nil, dateIsEstimate: false)
    ]
    var results: [Event] {
        if searchString.isEmpty {
            return allEvents
        } else {
            return allEvents.filter({ $0.title.localizedCaseInsensitiveContains(searchString) })
        }
    }
    
    @EnvironmentObject var eventsData: EventsData
    @State var searchString = ""
    
    var body: some View {
        List(results) { event in
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.title2)
                    Text(event.subtitle)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if eventsData.events.contains(event) {
                    Button("Remove") {
                        eventsData.events.removeAll(where: { $0.id == event.id })
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .fontWeight(.bold)
                } else {
                    Button("ADD") {
                        Task {
                            await event.fetch()
                        }
                        eventsData.events.append(event)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .fontWeight(.bold)
                }
            }
        }
        .navigationTitle("Common Events")
        .searchable(text: $searchString, prompt: "Search")
    }
}

struct CommonEventsList_Previews: PreviewProvider {
    static var previews: some View {
        CommonEventsList()
    }
}
