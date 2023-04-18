//
//  NewDateEstimateView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-01-16.
//

import SwiftUI

struct NewDateEstimateView: View {
    
    let event: Event
    
    @EnvironmentObject var eventsData: EventsData
    @Environment(\.dismiss) var dismiss
    
    @State var dateEstimate = Date.now
    
    var body: some View {
        Form {
            Section {
                DatePicker("Date Estimate", selection: $dateEstimate, displayedComponents: .date)
            }
            Section {
                Label("This estimated event will be shown until we find a confirmed release date to replace it.", systemImage: "info.circle")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let index = eventsData.events.firstIndex(of: event) {
                        event.date = dateEstimate
                        event.dateIsEstimate = true
                        eventsData.save()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("\(event.title) Estimate")
    }
}

struct NewDateEstimateView_Previews: PreviewProvider {
    static var previews: some View {
        NewDateEstimateView(event: Event(id: "", dataSource: nil, title: "Event", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: nil, dateIsEstimate: false))
    }
}
