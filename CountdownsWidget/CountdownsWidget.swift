//
//  CountdownsWidget.swift
//  CountdownsWidget
//
//  Created by 256 Arts Developer on 2022-11-30.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, events: [
            Event(id: "1", dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false),
            Event(id: "2", dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false),
            Event(id: "3", dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: .now, dateIsEstimate: false)
        ], relevance: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let entry = SimpleEntry(date: .now, events: await fetchEvents(), relevance: nil)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let events = await fetchEvents()
            let tomorow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
            let relenanceScore: Float = {
                if let firstEvent = events.first, let daysUntil = firstEvent.daysUntil {
                    // 0 days away = 30 score
                    // 1 day away = 29 score
                    // 30+ days away = 1 score
                    return min(1, Float(30 - daysUntil))
                }
                return 0
            }()
            let entry = SimpleEntry(date: .now, events: events, relevance: .init(score: relenanceScore, duration: tomorow.timeIntervalSinceNow))
            
            let timeline = Timeline(entries: [entry], policy: .after(tomorow))
            completion(timeline)
        }
    }
    
    func fetchEvents() async -> [Event] {
        do {
            let eventsData = try await CloudController.shared.fetchEventsData() ?? EventsData(fileVersion: 0)
            await eventsData.refresh()
            let events = Array(eventsData.upcomingEvents.prefix(6))
            
            if let firstEvent = events.first, firstEvent.daysUntil == 0 {
                try await firstEvent.preloadImage(large: true)
            } else {
                try? await preloadThumbnails(events)
            }
            return events
        } catch {
            return []
        }
    }
    
    func preloadThumbnails(_ events: [Event]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for event in events {
                group.addTask {
                    try await event.preloadImage(large: false)
                }
            }
            try await group.waitForAll()
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let events: [Event]
    let relevance: TimelineEntryRelevance?
}

struct CountdownsWidgetEntryView: View {
    
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.events.isEmpty {
                Text("No Countdowns")
                    .foregroundColor(.secondary)
            } else if entry.events.first?.daysUntil == 0 {
                CountdownWidgetFeaturedEvent(event: entry.events.first!)
            } else {
                GeometryReader { geometry in
                    VStack(spacing: family == .systemMedium ? 0 : 8) {
                        ForEach(entry.events.indices) { index in
                            CountdownWidgetEventCard(event: entry.events[index])
                                .scaleEffect(rowScale(index: index))
                                .frame(height: CountdownWidgetEventCard.height * rowScale(index: index))
                                .zIndex(Double(10 - index))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .padding(8)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .accentColor(Color("AccentColor"))
    }
    
    func rowScale(index: Int) -> CGFloat {
        if family == .systemMedium {
            switch index {
            case 0:
                return 1
            case 1:
                return 0.9
            case 2:
                return 0.8
            default:
                return 0.7
            }
        } else {
            switch index {
            case 0:
                return 1
            case 1:
                return 0.95
            case 2:
                return 0.9
            case 3:
                return 0.85
            case 4:
                return 0.8
            default:
                return 0.75
            }
        }
    }
}

struct CountdownWidgetEventCard: View {
    
    static let height: CGFloat = 52
    
    let event: Event
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(event.daysUntilString)
                .font(.title)
                .allowsTightening(true)
                .minimumScaleFactor(0.5)
                .frame(width: 64)
            
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(Color.accentColor.gradient)
            case .remote:
                EmptyView()
            case .preloaded(let data):
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                        .frame(maxWidth: 31, maxHeight: 47)
                }
            }
            
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                if let date = event.date {
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .lineLimit(1)
        .padding(.horizontal, 6)
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .frame(height: Self.height)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(white: 0.0, opacity: colorScheme == .light ? 0.17 : 0.36), radius: 4)
    }
}

struct CountdownWidgetFeaturedEvent: View {
    
    let event: Event
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        HStack(spacing: 0) {
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(Color.accentColor.gradient)
                    .font(.system(size: 100))
                    .padding()
            case .remote:
                EmptyView()
            case .preloaded(let data):
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(family == .systemMedium ? 0 : 5)
                }
            }
            VStack(spacing: 10) {
                Text(event.title)
                    .font(.system(size: 24, weight: .medium))
                Text("Today")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding()
            .frame(idealWidth: .infinity, maxWidth: .infinity)
        }
        .background {
            ZStack {
                switch event.icon {
                case .preloaded(let data):
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                default:
                    EmptyView()
                }
                Rectangle().fill(Material.regular)
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

struct CountdownsWidget: Widget {
    let kind: String = "CountdownsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CountdownsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CountdownsWidget_Previews: PreviewProvider {
    static var previews: some View {
        CountdownsWidgetEntryView(entry: SimpleEntry(date: .now, events: [], relevance: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
