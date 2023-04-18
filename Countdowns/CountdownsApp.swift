//
//  CountdownsApp.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI

@main
struct CountdownsApp: App {
    
    @ObservedObject var cloudController: CloudController = .shared
    
    @State var selectedEvent: Event?
    
    var body: some Scene {
        WindowGroup {
            if let eventsData = cloudController.eventsData {
                NavigationSplitView {
                    UpcomingList()
                } detail: {
                    NavigationStack {
                        if let selectedEvent {
                            EventView(event: selectedEvent)
                        } else {
                            Text("No Content Selected")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .environmentObject(eventsData)
            } else if cloudController.decodeError != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Failed to load data.")
                }
            } else {
                ProgressView()
                    .controlSize(.large)
            }
        }
    }
}
