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
    @State var showingHelp = false
    @State var showingNewCommonEvent = false
    @State var showingNewMovieTVEvent = false
    @State var showingNewDateEvent = false
    @State var showingEventSources = false
    @State var fullScreenEvent: Event?
    
    var results: [Event] {
        if searchString.isEmpty {
            return allEvents.upcoming
        } else {
            return allEvents.upcoming.filter({ $0.title?.localizedCaseInsensitiveContains(searchString) ?? false })
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
                Button {
                    fullScreenEvent = event
                } label: {
                    Label("View Fullscreen", systemImage: "arrow.up.backward.and.arrow.down.forward")
                }
                Button(role: .destructive) {
                    modelContext.delete(event)
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions {
                Button(role: .destructive) {
                    modelContext.delete(event)
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonBorderShape(.circle)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingNewCommonEvent = true
                    } label: {
                        Label("Common Event", systemImage: "star")
                    }
                    Button {
                        showingNewMovieTVEvent = true
                    } label: {
                        Label("Movie/TV Release", systemImage: "film")
                    }
                    Button {
                        showingNewDateEvent = true
                    } label: {
                        Label("Custom", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonBorderShape(.circle)
            }
            #if !os(macOS)
            if hasEventsWithMissingDates {
                ToolbarItem(placement: .bottomBar) {
                    Button("Events Missing Dates") {
                        showingEventSources = true
                    }
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
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                HelpView()
            }
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
            FullScreenEventView(event: event)
        }
        #else
        .fullScreenCover(item: $fullScreenEvent) { event in
            FullScreenEventView(event: event)
        }
        #endif
    }
}

#Preview {
    UpcomingList()
}
