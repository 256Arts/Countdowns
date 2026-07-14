import SwiftUI
import SwiftData
import AppIntents
#if canImport(WidgetKit)
import WidgetKit
#endif

struct UpcomingList: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [Event]
    
    private var calendarService: CalendarService = .shared
    
    @State var searchString = ""
    @State var showingNewCommonEvent = false
    @State var showingNewMovieTVEvent = false
    @State var showingNewDateEvent = false
    @State var showingImportCalendar = false
    @State var showingEventSources = false
    @State var isUpdatingCalendarEvents = false
    
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
            // Tie each visible row to its entity so Siri is aware of the on-screen list.
            .appEntityIdentifier(EntityIdentifier(for: EventEntity.self, identifier: event.entityIdentifier))
            .contextMenu {
                deleteEventButton(event: event)
            }
            .swipeActions {
                deleteEventButton(event: event)
            }
        }
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                addMenu
            }
            #else
            // Primary action stays pinned to the trailing edge and never overflows.
            ToolbarItem(placement: .topBarPinnedTrailing) {
                addMenu
            }

            // Secondary links always live in the trailing overflow menu.
            ToolbarOverflowMenu {
                CountdownsApp.links()
            }

            if hasEventsWithMissingDates {
                // A contextual warning: shown in the bar when there's room, first to overflow when space is tight.
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Events Missing Dates", systemImage: "exclamationmark.triangle") {
                        showingEventSources = true
                    }
                }
                #if os(iOS)
                .visibilityPriority(.low)
                #endif
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
        .sheet(isPresented: $showingImportCalendar) {
            NavigationStack {
                ImportCalendarView()
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
        .task {
            for await _ in calendarService.calendarUpdates {
                guard await calendarService.store.isFullAccessAuthorized else { return }
                
                await calendarService.regenerateCalendarEvents(modelContext: modelContext, allEvents: allEvents)
            }
        }
    }
    
    @ViewBuilder
    private var addMenu: some View {
        Menu("Add", systemImage: "plus") {
            Button("Common Event", systemImage: "star") {
                showingNewCommonEvent = true
            }
            Button("Import Calendar", systemImage: "calendar") {
                showingImportCalendar = true
            }
            Button("Movie/TV Release", systemImage: "film") {
                showingNewMovieTVEvent = true
            }
            Button("Custom", systemImage: "square.and.pencil") {
                showingNewDateEvent = true
            }
        }
    }

    @ViewBuilder
    private func deleteEventButton(event: Event) -> some View {
        if case .calendar = event.dataSource {
            Button("Remove Calendar", systemImage: "calendar.badge.minus", role: .destructive) {
                let otherEventsFromThisCalendar = allEvents.filter { $0.dataSource == event.dataSource }
                for event in otherEventsFromThisCalendar {
                    modelContext.delete(event)
                }
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        } else {
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(event)
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
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
        
        await calendarService.regenerateCalendarEvents(modelContext: modelContext, allEvents: allEvents)

        // Donate the refreshed events to Spotlight so Siri can surface them.
        try? await EventStore.indexEntities()
    }

}

#Preview {
    UpcomingList()
}
