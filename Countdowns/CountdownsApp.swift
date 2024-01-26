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
        .modelContainer(for: Event.self)
        #if os(macOS)
        .defaultSize(width: 650, height: 400)
        #else
        .defaultSize(width: 700, height: 600)
        #endif
    }
}
