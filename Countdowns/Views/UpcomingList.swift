//
//  UpcomingList.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI

struct UpcomingList: View {
    
    @EnvironmentObject var eventsData: EventsData
    @State var searchString = ""
    @State var showingNewCommonEvent = false
    @State var showingNewMovieTVEvent = false
    @State var showingNewDateEvent = false
    @State var showingEventSources = false
    
    var results: [Event] {
        if searchString.isEmpty {
            return eventsData.upcomingEvents
        } else {
            return eventsData.upcomingEvents.filter({ $0.title.localizedCaseInsensitiveContains(searchString) })
        }
    }
    
    var body: some View {
        List(results) { event in
            NavigationLink(value: event) {
                HStack {
                    Text(event.daysUntilString)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                        .font(.title)
                        .frame(width: 80)
                    
                    switch event.icon {
                    case .symbolIcon(name: let name):
                        Image(systemName: name)
                            .symbolVariant(.fill)
                            .foregroundStyle(Color.accentColor.gradient)
                    case .remote(let url):
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Color.secondary
                        }
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(6)
                        .frame(width: 40, height: 60)
                    case .preloaded:
                        EmptyView()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .lineLimit(1)
                            .font(.title2)
                        Text(event.date!, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    if let index = eventsData.events.firstIndex(where: { $0.id == event.id }) {
                        eventsData.events.remove(at: index)
                    }
                } label: {
                    Label("Delete Event Source", systemImage: "trash")
                }
            }
        }
        .toolbar {
            ToolbarItem {
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
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Events Missing Dates") {
                    showingEventSources = true
                }
            }
        }
        .navigationTitle("Upcoming Events")
        .navigationDestination(for: Event.self) { event in
            EventView(event: event)
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await eventsData.refresh()
        }
        .sheet(isPresented: $showingNewCommonEvent) {
            NavigationStack {
                DiscoverView()
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
        .task {
            await eventsData.refresh()
        }
    }
}

struct EventPublishersList_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingList()
    }
}
