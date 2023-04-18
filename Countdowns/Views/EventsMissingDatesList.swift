//
//  EventsMissingDatesList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-01-14.
//

import SwiftUI

struct EventsMissingDatesList: View {
    
    @EnvironmentObject var eventsData: EventsData
    
    @State var sourceForNewEstimate: Event?
    
    var body: some View {
        List($eventsData.events, editActions: .delete) { $event in
            Text(event.title)
                .contextMenu {
                    Button {
                        sourceForNewEstimate = event
                    } label: {
                        Label("Add Estimate", systemImage: "calendar.badge.plus")
                    }
                    Button(role: .destructive) {
                        eventsData.events.removeAll(where: { $0.id == event.id })
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .toolbar {
            EditButton()
        }
        .navigationTitle("Event Sources")
        .sheet(item: $sourceForNewEstimate) { event in
            NavigationStack {
                NewDateEstimateView(event: event)
            }
        }
    }
}

struct EventSourcesList_Previews: PreviewProvider {
    static var previews: some View {
        EventsMissingDatesList()
    }
}
