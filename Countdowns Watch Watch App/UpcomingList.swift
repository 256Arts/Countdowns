//
//  UpcomingList.swift
//  Countdowns Watch Watch App
//
//  Created by 256 Arts Developer on 2023-09-27.
//

import SwiftUI
import SwiftData

struct UpcomingList: View {
    
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
