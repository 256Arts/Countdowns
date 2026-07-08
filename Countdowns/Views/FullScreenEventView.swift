//
//  FullScreenEventView.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import SwiftUI
import AppIntents

struct FullScreenEventView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditor = false
    
    @Bindable var event: Event
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 40)
            
            switch event.icon {
            case .symbolIcon(name: let name):
                HStack {
                    Image(systemName: name)
                        .symbolVariant(.fill)
                        .foregroundStyle(event.colorName?.color.gradient ?? Color.accentColor.gradient)
                    
                    Text(event.title ?? "")
                }
                .font(.largeTitle)
            case .remote(let url):
                Text(event.title ?? "")
                    .font(.largeTitle)
                
                AsyncImage(url: URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: "/w500/"))!) { image in
                    image.resizable()
                } placeholder: {
                    Color.secondary
                }
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerRadius: 20))
                .frame(minWidth: 200, idealWidth: 300, minHeight: 300, idealHeight: 450)
            case .preloaded, nil:
                EmptyView()
            }
            
            Spacer()
            
            if let date = event.date {
                VStack {
                    if event.dateIsEstimate == true {
                        Text("Expected:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Text(event.daysUntilString + " days")
                        .font(.largeTitle)
                    Text(date, style: .date)
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
            }
            
            Spacer()
            
            if case .recurrence = event.dataSource {
                Text("Repeats Yearly")
                    .foregroundStyle(.secondary)
            }
        }
        .scenePadding()
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        #if !os(visionOS)
        .background {
            if case .remote(let url) = event.icon {
                AsyncImage(url: URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: "/w500/"))!) { image in
                    image.resizable()
                } placeholder: {
                    EmptyView()
                }
                .scaledToFill()
                .overlay(Material.thin)
                .ignoresSafeArea()
            } else {
                ZStack {
                    event.colorName?.color
                    Color.black.opacity(0.75)
                }
                .ignoresSafeArea()
            }
        }
        #endif
        .toolbar {
            if event.isEditable {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditor = true
                    }
                    .popover(isPresented: $showingEditor, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) {
                        #if os(macOS)
                        EditCustomEventView(event: event)
                            .frame(idealHeight: 400)
                        #else
                        NavigationStack {
                            EditCustomEventView(event: event)
                        }
                        .frame(idealWidth: 360, idealHeight: 700)
                        #endif
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        // Tell Siri which countdown is on screen, so "how many days until this?" resolves to it.
        .userActivity("com.256arts.countdowns.viewing-event", element: event.asEntity()) { entity, activity in
            activity.title = event.title
            activity.appEntityIdentifier = .init(for: entity)
        }
    }
}

#Preview {
    FullScreenEventView(event: Event(dataSource: nil, title: "Content", colorName: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false))
}
