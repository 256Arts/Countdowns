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
        .commands {
            CommandGroup(after: .help) {
                Self.links()
            }
        }
        #if targetEnvironment(simulator) || (DEBUG && os(macOS))
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
    
    @ViewBuilder
    static func links() -> some View {
        Link(destination: URL(string: "https://www.256arts.com/")!) {
            Label("Developer Website", systemImage: "safari")
        }
        Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
            Label("Join Community", systemImage: "bubble.left.and.bubble.right")
        }
        Link(destination: URL(string: "https://github.com/256Arts/Countdowns")!) {
            Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
        }
    }
    
}
