//
//  CountdownsWidget.swift
//  CountdownsWidget
//
//  Created by 256 Arts Developer on 2022-11-30.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    
    private let modelContext = ModelContext(try! ModelContainer(for: Event.self, configurations: .init(cloudKitDatabase: .private("iCloud.com.256arts.countdowns"))))
    
    func placeholder(in context: Context) -> SimpleEntry {
        let tomorow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: .now)
        return SimpleEntry(date: .now, events: [
            Event(dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: tomorow, dateIsEstimate: false),
            Event(dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: tomorow, dateIsEstimate: false),
            Event(dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "circle"), date: tomorow, dateIsEstimate: false)
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
            let calendar = Calendar.autoupdatingCurrent
            let tomorow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
            let relevanceScore = Float(events.first?.relevanceScore ?? 0)
            let entry = SimpleEntry(date: .now, events: events, relevance: .init(score: relevanceScore, duration: tomorow.timeIntervalSinceNow))
            
            let timeline = Timeline(entries: [entry], policy: .after(tomorow))
            completion(timeline)
        }
    }
    
    func fetchEvents() async -> [Event] {
        do {
            let events = Array(try modelContext.fetch(FetchDescriptor<Event>()).upcoming.prefix(6))
            
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
    
    #if canImport(UIKit)
    let containerBackgroundColor = Color(uiColor: .systemGroupedBackground)
    #else
    let containerBackgroundColor = Color(nsColor: .windowBackgroundColor)
    #endif
    
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            #if !os(macOS)
            case .accessoryInline:
                if let event = entry.events.first {
                    let days = event.daysUntil == 0 ? "🎉" : "\(event.daysUntilString)d •"
                    Text("\(days) \(event.title ?? "")")
                        .widgetAccentable()
                } else {
                    Text("No Countdowns")
                        .foregroundColor(.secondary)
                }
            case .accessoryCircular:
                VStack {
                    if let event = entry.events.first {
                        Text(event.daysUntil == 0 ? "🎉" : "\(event.daysUntilString)d")
                            .font(.title)
                        Text(event.title ?? "")
                            .widgetAccentable()
                    } else {
                        Text("No Countdowns")
                            .foregroundColor(.secondary)
                    }
                }
                .lineLimit(1)
                .containerBackground(containerBackgroundColor, for: .widget)
            case .accessoryRectangular:
                Grid(alignment: .leading) {
                    if entry.events.isEmpty {
                        Text("No Countdowns")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(entry.events.prefix(3))) { event in
                            GridRow {
                                Text("\(event.daysUntilString)d")
                                    .gridColumnAlignment(.trailing)
                                Text(event.title ?? "")
                                    .lineLimit(1)
                                    .widgetAccentable()
                            }
                        }
                    }
                }
                .containerBackground(containerBackgroundColor, for: .widget)
            #endif
            #if !os(watchOS)
            case .systemSmall:
                Group {
                    if let event = entry.events.first {
                        VStack(alignment: .leading) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(event.daysUntil == 0 ? "Today" : event.daysUntilString)
                                    .font(.system(size: 46))
                                if event.daysUntil != 0 {
                                    Text("days")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text(event.title ?? "")
                                .font(.system(size: 28))
                                .lineLimit(2)
                        }
                        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity, alignment: .leading)
                        .overlay(alignment: .topTrailing) {
                            if case .symbolIcon(let name) = event.icon {
                                Image(systemName: name)
                                    .imageScale(.large)
                                    .symbolVariant(.fill)
                                    .foregroundStyle(Color.accentColor.gradient)
                            }
                        }
                    } else {
                        Text("No Countdowns")
                            .foregroundColor(.secondary)
                    }
                }
                .containerBackground(containerBackgroundColor, for: .widget)
            #endif
            default:
                #if os(watchOS)
                EmptyView()
                #else
                if entry.events.isEmpty {
                    Text("No Countdowns")
                        .foregroundColor(.secondary)
                        .containerBackground(containerBackgroundColor, for: .widget)
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
                    .containerBackground(containerBackgroundColor, for: .widget)
                }
                #endif
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
    
    static let height: CGFloat = 56
    
    let event: Event
    #if canImport(UIKit)
    let backgroundColor = Color(uiColor: .secondarySystemGroupedBackground)
    #else
    let backgroundColor = Color(nsColor: .quaternarySystemFill)
    #endif
    
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
            case .remote, nil:
                EmptyView()
            case .preloaded(let data):
                #if canImport(UIKit)
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                        .frame(maxWidth: 35, maxHeight: 52)
                }
                #else
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                        .frame(maxWidth: 35, maxHeight: 52)
                }
                #endif
            }
            
            VStack(alignment: .leading) {
                Text(event.title ?? "")
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
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(white: 0.0, opacity: colorScheme == .light ? 0.17 : 0.36), radius: 4)
    }
}

struct CountdownWidgetFeaturedEvent: View {
    
    let event: Event
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            switch event.icon {
            case .symbolIcon(name: let name):
                Image(systemName: name)
                    .symbolVariant(.fill)
                    .foregroundStyle(Color.accentColor.gradient)
                    .font(.system(size: 100))
                    .padding()
            case .remote, nil:
                EmptyView()
            case .preloaded:
                backgroundImage?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(family == .systemMedium ? 0 : 5)
            }
            VStack(spacing: 10) {
                Text(event.title ?? "")
                    .font(.system(size: 24, weight: .medium))
                Text("Today")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding()
            .frame(idealWidth: .infinity, maxWidth: .infinity)
        }
        .containerBackground(for: .widget) {
            ZStack {
                backgroundImage?
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                
                Rectangle().fill(Material.regular)
            }
        }
        .environment(\.colorScheme, backgroundImage == nil ? systemColorScheme : .dark)
    }
    
    private var backgroundImage: Image? {
        if case .preloaded(let data) = event.icon {
            #if canImport(UIKit)
            if let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            } else {
                return nil
            }
            #else
            if let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            } else {
                return nil
            }
            #endif
        }
        return nil
    }
}

struct CountdownsWidget: Widget {
    let kind: String = "CountdownsWidget"
    
    var families: [WidgetFamily] {
        #if os(watchOS)
        [.accessoryInline, .accessoryCircular, .accessoryRectangular]
        #elseif os(iOS)
        [.accessoryInline, .accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium, .systemLarge]
        #else
        [.systemSmall, .systemMedium, .systemLarge]
        #endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CountdownsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Events")
        .description("A list of upcoming events.")
        .supportedFamilies(families)
    }
}

#if DEBUG
let previewEvents = [
    Event(dataSource: nil, title: "Birthday", colorHEX: nil, icon: .symbolIcon(name: "star"), date: .now.addingTimeInterval(999999), dateIsEstimate: false),
    Event(dataSource: nil, title: "Super Big Long Celebration Party", colorHEX: nil, icon: .symbolIcon(name: "star"), date: .now.addingTimeInterval(9999999), dateIsEstimate: false)
]

#if !os(macOS)
#Preview("Inline", as: WidgetFamily.accessoryInline) {
    CountdownsWidget()
} timeline: {
    SimpleEntry(date: .now, events: previewEvents, relevance: nil)
}

#Preview("Circle", as: WidgetFamily.accessoryCircular) {
    CountdownsWidget()
} timeline: {
    SimpleEntry(date: .now, events: previewEvents, relevance: nil)
}

#Preview("Rect", as: WidgetFamily.accessoryRectangular) {
    CountdownsWidget()
} timeline: {
    SimpleEntry(date: .now, events: previewEvents, relevance: nil)
}
#endif

#Preview("Small", as: WidgetFamily.systemSmall) {
    CountdownsWidget()
} timeline: {
    SimpleEntry(date: .now, events: previewEvents, relevance: nil)
}

#Preview("Medium", as: WidgetFamily.systemMedium) {
    CountdownsWidget()
} timeline: {
    SimpleEntry(date: .now, events: previewEvents, relevance: nil)
}

#Preview("Large", as: WidgetFamily.systemLarge) {
    CountdownsWidget()
} timeline: {
    SimpleEntry(date: .now, events: previewEvents, relevance: nil)
}
#endif
