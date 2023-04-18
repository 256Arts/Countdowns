//
//  EventView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI

struct EventView: View {
    
    @EnvironmentObject var eventsData: EventsData
    
    let event: Event
    
    var body: some View {
        VStack {
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(Color.accentColor.gradient)
                    .font(.system(size: 64))
            case .remote(let url):
                AsyncImage(url: URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: "/w500/"))!) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(6)
                .frame(width: 300, height: 450)
            case .preloaded:
                EmptyView()
            }
            
            Spacer()
            
            if let date = event.date {
                VStack {
                    if event.dateIsEstimate {
                        Text("Expected:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Text(event.daysUntilString + " days")
                        .font(.largeTitle)
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            
            Spacer()
            
            if case .recurrence = event.dataSource {
                Text("Repeats Yearly")
                    .foregroundColor(.secondary)
            }
        }
        .scenePadding()
        .navigationTitle(event.title)
        .toolbar {
            Button(role: .destructive) {
                if let index = eventsData.events.firstIndex(where: { $0.id == event.id }) {
                    eventsData.events.remove(at: index)
                }
            } label: {
                Label("Delete Event Source", systemImage: "trash")
            }
        }
    }
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        EventView(event: Event(id: "", dataSource: nil, title: "Content", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
    }
}
