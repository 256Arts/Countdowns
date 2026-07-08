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
    
    init() {
        UserDefaults.standard.register()
    }
    
    @State private var navigation = AppNavigation.shared
    @State private var showingAppStoreEvent = false

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                UpcomingList()
            } detail: {
                NavigationStack {
                    if let selectedEvent = navigation.selectedEvent {
                        FullScreenEventView(event: selectedEvent)
                    } else {
                        Text("No Content Selected")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Event Intro", isPresented: $showingAppStoreEvent) {
                Button("OK", role: .close) { }
            } message: {
                Text("Now let's celebrate by adding the event through the \"+\" menu, and trying out the new features!")
            }
            .onOpenURL { url in
                if url.path().contains("countdowns/appstoreevent") {
                    showingAppStoreEvent = true
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
        .modelContainer(ModelContainer.shared)
        #endif
        #if os(macOS)
        .defaultSize(width: 500, height: 300)
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
