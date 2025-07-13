//
//  CountdownsApp.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI
import SwiftData

@main
struct CountdownsApp: App {
    
    @State var selectedEvent: Event?
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                UpcomingList()
            } detail: {
                NavigationStack {
                    if let selectedEvent {
                        FullScreenEventView(event: selectedEvent)
                    } else {
                        Text("No Content Selected")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        #if targetEnvironment(simulator) || (DEBUG && targetEnvironment(macCatalyst))
        .modelContainer(previewContainer)
        #else
        .modelContainer(for: Event.self)
        #endif
        #if os(macOS)
        .defaultSize(width: 650, height: 400)
        #else
        .defaultSize(width: 700, height: 600)
        #endif
    }
    
    #if DEBUG
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: Event.self, configurations: config)

        for event in CommonEventsList().allEvents.filter({ !$0.dateIsEstimate! }) {
            container.mainContext.insert(event)
            Task {
                await event.fetch()
            }
        }
        
        return container
    }()
    #endif
}
