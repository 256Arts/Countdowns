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
            NavigationLink(value: event) {
                EventRow(event: event)
            }
            .contextMenu {
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
            FullScreenEventView(event: event)
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await refreshEvents()
        }
        .sheet(isPresented: $showingNewCommonEvent) {
            NavigationStack {
                CommonEventsList()
            }
            #if os(macOS)
            .frame(idealHeight: 400)
            #endif
        }
        .sheet(isPresented: $showingNewMovieTVEvent) {
            NavigationStack {
                NewMovieSourceView()
            }
            #if os(macOS)
            .frame(idealHeight: 400)
            #endif
        }
        .sheet(isPresented: $showingNewDateEvent) {
            NavigationStack {
                NewCustomEventView()
            }
            #if os(macOS)
            .frame(idealHeight: 400)
            #endif
        }
        .sheet(isPresented: $showingEventSources) {
            NavigationStack {
                EventsMissingDatesList()
            }
            #if os(macOS)
            .frame(idealHeight: 400)
            #endif
        }
        .task {
            await refreshEvents()
        }
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
