//
//  EventsMissingDatesList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-01-14.
//

import SwiftUI
import SwiftData

struct EventsMissingDatesList: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Event>{
        $0.date == nil
    }) private var eventsMissingDates: [Event]
    
    @State var sourceForNewEstimate: Event?
    
    var body: some View {
        List {
            Section {
                if eventsMissingDates.isEmpty {
                    Text("No events")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(eventsMissingDates) { event in
                        Text(event.title ?? "")
                            .contextMenu {
                                Button("Add Estimate", systemImage: "calendar.badge.plus") {
                                    sourceForNewEstimate = event
                                }
                                
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(event)
                                }
                            }
                    }
                    .onDelete(perform: delete)
                }
            } footer: {
                Text("You added these upcoming events, but the data source doesn't have a date for them yet. When the data source updates the date, the event will appear in your \"Upcoming Events\" list.")
            }
        }
        #if !os(macOS)
        .toolbar {
            EditButton()
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Close", systemImage: "xmark") {
                    dismiss()
                }
            }
        }
        .navigationTitle("Events Missing Dates")
        .sheet(item: $sourceForNewEstimate) { event in
            NavigationStack {
                NewDateEstimateView(event: event)
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for event in offsets.map({ eventsMissingDates[$0] }) {
            modelContext.delete(event)
        }
    }
}

#Preview {
    EventsMissingDatesList()
}
