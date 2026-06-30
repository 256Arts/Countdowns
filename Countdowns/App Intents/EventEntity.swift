//
//  EventEntity.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2026-06-29.
//

import AppIntents
import CoreSpotlight
import SwiftData

/// An `Event` exposed to Siri, Spotlight, and Shortcuts.
///
/// Backed by SwiftData: the `id` is an encoded `PersistentIdentifier`, so the entity can be resolved
/// back to its `Event` in the shared model container (see `EventStore`).
///
/// Conforms to `IndexedEntity` so events can be donated to the on-device Spotlight index
/// (`EventStore.indexEntities`); without that, Siri and Spotlight can't surface individual countdowns.
struct EventEntity: AppEntity, IndexedEntity, Identifiable {

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Event")
    static let defaultQuery = EventEntityQuery()

    let id: String

    @Property(title: "Title")
    var title: String

    @Property(title: "Date")
    var date: Date?

    @Property(title: "Days Until")
    var daysUntil: Int?

    init(id: String, title: String, date: Date?, daysUntil: Int?) {
        self.id = id
        self.title = title
        self.date = date
        self.daysUntil = daysUntil
    }

    /// A short human-readable description of when this event occurs.
    var subtitle: String {
        if let daysUntil {
            switch daysUntil {
            case 0: "Today"
            case 1: "Tomorrow"
            case ..<0: "Past"
            default: "in \(daysUntil) days"
            }
        } else if let date {
            date.formatted(date: .abbreviated, time: .omitted)
        } else {
            ""
        }
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    /// Spotlight metadata used when the entity is indexed via `IndexedEntity`.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = title
        attributes.contentDescription = subtitle
        attributes.startDate = date
        return attributes
    }
}

extension EventEntity {

    @MainActor
    init(_ event: Event) {
        self.init(
            id: event.persistentModelID.entityIDString ?? "",
            title: event.title ?? "Untitled Event",
            date: event.date,
            daysUntil: event.daysUntil)
    }
}

// Identity-based equality so `EventEntity` can scope a SwiftUI `.userActivity(_:element:_:)`.
extension EventEntity: Hashable {

    static func == (lhs: EventEntity, rhs: EventEntity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Event {

    /// The stable identifier that ties this event's on-screen views to its `EventEntity`,
    /// so Siri can answer questions about whichever countdown is currently visible.
    var entityIdentifier: String {
        persistentModelID.entityIDString ?? ""
    }

    /// This event as an `AppEntity` exposed to Siri, Spotlight, and Shortcuts.
    @MainActor
    func asEntity() -> EventEntity {
        EventEntity(self)
    }
}

/// Resolves `EventEntity` values for Siri/Shortcuts by querying the shared SwiftData container.
struct EventEntityQuery: EntityQuery {

    @MainActor
    func entities(for identifiers: [EventEntity.ID]) async throws -> [EventEntity] {
        let wanted = Set(identifiers)
        return try EventStore.upcomingEntities().filter { wanted.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [EventEntity] {
        try EventStore.upcomingEntities()
    }
}

extension EventEntityQuery: EntityStringQuery {

    @MainActor
    func entities(matching string: String) async throws -> [EventEntity] {
        try EventStore.upcomingEntities().filter {
            $0.title.localizedCaseInsensitiveContains(string)
        }
    }
}

/// Bridges App Intents to the shared SwiftData store.
@MainActor
enum EventStore {

    static var context: ModelContext { ModelContainer.shared.mainContext }

    static func upcomingEvents() throws -> [Event] {
        try context.fetch(FetchDescriptor<Event>()).upcoming
    }

    static func upcomingEntities() throws -> [EventEntity] {
        try upcomingEvents().map(EventEntity.init)
    }

    static func event(id: String) throws -> Event? {
        guard let identifier = PersistentIdentifier(entityIDString: id) else { return nil }
        return try context.fetch(FetchDescriptor<Event>()).first { $0.persistentModelID == identifier }
    }

    /// Donates the current upcoming events to the on-device Spotlight index so Siri and
    /// Spotlight can surface them. Call after the event list changes (e.g. after a refresh).
    static func indexEntities() async throws {
        try await CSSearchableIndex.default().indexAppEntities(upcomingEntities())
    }
}

extension PersistentIdentifier {

    /// A portable string form usable as an `AppEntity.ID`.
    var entityIDString: String? {
        try? JSONEncoder().encode(self).base64EncodedString()
    }

    init?(entityIDString string: String) {
        guard let data = Data(base64Encoded: string),
              let identifier = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) else {
            return nil
        }
        self = identifier
    }
}
