//
//  UpcomingList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

struct UpcomingList: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [Event]
    
    @State var searchString = ""
    @State var showingNewCommonEvent = false
    @State var showingNewMovieTVEvent = false
    @State var showingNewDateEvent = false
    @State var showingEventSources = false
    @State var fullScreenEvent: Event?
    
    var results: [Event] {
        if searchString.isEmpty {
            allEvents.upcoming
        } else {
            allEvents.upcoming.filter({ $0.title?.localizedCaseInsensitiveContains(searchString) ?? false })
        }
    }
    var hasEventsWithMissingDates: Bool {
        allEvents.contains(where: { $0.date == nil })
    }
    
    var body: some View {
        List(results) { event in
            Group {
                if event.isEditable {
                    NavigationLink(value: event) {
                        EventRow(event: event)
                    }
                } else {
                    EventRow(event: event)
                }
            }
            .contextMenu {
                Button("View Fullscreen", systemImage: "arrow.up.backward.and.arrow.down.forward") {
                    fullScreenEvent = event
                }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    modelContext.delete(event)
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }
            }
            .swipeActions {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    modelContext.delete(event)
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Add", systemImage: "plus") {
                    Button("Common Event", systemImage: "star") {
                        showingNewCommonEvent = true
                    }
                    Button("Movie/TV Release", systemImage: "film") {
                        showingNewMovieTVEvent = true
                    }
                    Button("Custom", systemImage: "square.and.pencil") {
                        showingNewDateEvent = true
                    }
                }
            }
            
            #if !os(macOS)
            ToolbarItemGroup(placement: .secondaryAction) {
                CountdownsApp.links()
            }
            
            if hasEventsWithMissingDates {
                ToolbarItem(placement: .bottomBar) {
                    Button("Events Missing Dates") {
                        showingEventSources = true
                    }
                    .controlSize(.small)
                }
            }
            #endif
        }
        #if os(visionOS)
        .navigationTitle("Events")
        #else
        .navigationTitle("Upcoming Events")
        #endif
        .navigationDestination(for: Event.self) { event in
            EditCustomEventView(event: event)
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await refreshEvents()
        }
        .sheet(isPresented: $showingNewCommonEvent) {
            NavigationStack {
                CommonEventsList()
            }
        }
        .sheet(isPresented: $showingNewMovieTVEvent) {
            NavigationStack {
                NewMovieSourceView()
            }
        }
        .sheet(isPresented: $showingNewDateEvent) {
            NavigationStack {
                NewCustomEventView()
            }
        }
        .sheet(isPresented: $showingEventSources) {
            NavigationStack {
                EventsMissingDatesList()
            }
        }
        #if os(macOS)
        .sheet(item: $fullScreenEvent) { event in
            NavigationStack {
                FullScreenEventView(event: event)
            }
        }
        #else
        .fullScreenCover(item: $fullScreenEvent) { event in
            NavigationStack {
                FullScreenEventView(event: event)
            }
        }
        #endif
//        .task {
//            await refreshEvents()
//        }
    }
    
    func refreshEvents() async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for event in allEvents {
                taskGroup.addTask {
                    await event.fetch()
                }
            }
            await taskGroup.waitForAll()
        }
    }
}

#Preview {
    UpcomingList()
}
