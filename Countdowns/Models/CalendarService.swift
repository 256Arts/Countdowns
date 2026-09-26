import Foundation
import Combine
import EventKit
import SwiftUI
import SwiftData

enum EventStoreError: Error {
    case denied
    case restricted
    case unknown
    case upgrade
}

extension EventStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .denied:
            return String(localized: "The app doesn't have permission to Calendar in Settings.", comment: "Access denied")
         case .restricted:
            return String(localized: "This device doesn't allow access to Calendar.", comment: "Access restricted")
        case .unknown:
            return String(localized: "An unknown error occured.", comment: "Unknown error")
        case .upgrade:
            let access = "The app has write-only access to Calendar in Settings."
            let update = "Please grant it full access so the app can fetch and delete your events."
            return String(localized: "\(access) \(update)", comment: "Upgrade to full access")
        }
    }
}

actor CalendarStore {
    
    let eventStore = EKEventStore()
    
    var allCalendars: [EKCalendar] {
        eventStore.calendars(for: .event)
    }
    
    var isFullAccessAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Prompts the user for full-access authorization to Calendar.
    private func requestFullAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }
    
    /// Verifies the authorization status for the app.
    func verifyAuthorizationStatus() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return try await requestFullAccess()
        case .restricted:
            throw EventStoreError.restricted
        case .denied:
            throw EventStoreError.denied
        case .fullAccess:
            return true
        case .writeOnly:
            throw EventStoreError.upgrade
        @unknown default:
            throw EventStoreError.unknown
        }
    }
    
    func calendar(withIdentifier identifier: String) -> EKCalendar? {
        eventStore.calendar(withIdentifier: identifier)
    }
    
    func fetchUpcomingOccurrences(calendarID: String, endDate: Date) throws -> [CalendarOccurrence] {
        guard let calendar = eventStore.calendar(withIdentifier: calendarID) else { throw CalendarService.ServiceError.calendarNotFound }
        guard isFullAccessAuthorized else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: .now, end: endDate, calendars: [calendar])
        return eventStore.events(matching: predicate).map { event in
            // Occurrences of a recurring event share an identifier, so the original occurrence date
            // tells them apart — and stays put when a single occurrence is moved.
            let identifier = event.calendarItemExternalIdentifier ?? event.eventIdentifier ?? ""
            let occurrenceDate = event.occurrenceDate ?? event.startDate ?? .distantPast
            return CalendarOccurrence(
                id: "\(identifier)|\(occurrenceDate.timeIntervalSinceReferenceDate)",
                title: event.title,
                date: event.startDate
            )
        }
    }
}

@MainActor @Observable
final class CalendarService {
    
    enum ServiceError: Error {
        case calendarNotFound
    }
    
    static let shared = CalendarService()
    let store = CalendarStore()
    
    /// Whether calendars are currently being converted into events in our database
    var isUpdatingCalendarEvents = false
    
    /// Listens for event store changes
    var calendarUpdates: NotificationCenter.Notifications {
        NotificationCenter.default.notifications(named: .EKEventStoreChanged)
    }
    
    var allCalendars: [EKCalendar] {
        get async {
            ScreenshotMode.isActive ? ScreenshotMode.demoCalendars : await store.allCalendars
        }
    }

    /// Confirms Calendar access, which a screenshot run's stand-in calendars do not need — and could
    /// not obtain anyway, since no one is there to answer the prompt.
    func verifyAuthorizationStatus() async throws -> Bool {
        guard !ScreenshotMode.isActive else { return true }

        return try await store.verifyAuthorizationStatus()
    }
    
    /// Brings each synced calendar's events in line with Calendar, touching only what changed.
    ///
    /// Events are matched by `calendarItemID` rather than deleted and reinserted, so an unchanged
    /// calendar writes nothing to CloudKit. Two devices that both insert the same new occurrence
    /// produce a duplicate once their stores merge; the next pass keeps one and deletes the rest.
    func regenerateCalendarEvents(modelContext: ModelContext, allEvents: [Event]) async {
        guard !isUpdatingCalendarEvents else { return }
        
        isUpdatingCalendarEvents = true
        let endDate = Date.now.addingTimeInterval(3 * 365 * 24 * 60 * 60)
        for info in allEvents.syncedCalendars {
            guard let occurrences = try? await store.fetchUpcomingOccurrences(calendarID: info.id, endDate: endDate) else { continue }
            
            var existingEvents: [String: Event] = [:]
            for event in allEvents where event.dataSource == .calendar(id: info.id) && !event.isDeleted {
                // Events without an ID predate matching (or are the import placeholder): replace them once
                guard let id = event.calendarItemID, existingEvents[id] == nil else {
                    modelContext.delete(event)
                    continue
                }
                existingEvents[id] = event
            }
            
            for occurrence in occurrences {
                if let event = existingEvents.removeValue(forKey: occurrence.id) {
                    if event.title != occurrence.title { event.title = occurrence.title }
                    if event.date != occurrence.date { event.date = occurrence.date }
                } else {
                    let event = Event(
                        dataSource: .calendar(id: info.id),
                        title: occurrence.title,
                        colorName: info.colorName,
                        icon: info.icon,
                        date: occurrence.date,
                        dateIsEstimate: false
                    )
                    event.calendarItemID = occurrence.id
                    modelContext.insert(event)
                }
            }
            for staleEvent in existingEvents.values {
                modelContext.delete(staleEvent)
            }
        }
        isUpdatingCalendarEvents = false
    }
    
}

/// One upcoming occurrence of a Calendar event, copied out of the `CalendarStore` actor.
struct CalendarOccurrence: Sendable {
    /// Stable across launches and devices: the event's external identifier plus its occurrence date.
    let id: String
    let title: String
    let date: Date
}

struct SyncedCalendarInfo {
    let id: String
    let colorName: ColorName?
    let icon: IconResource?
}

extension [Event] {
    var syncedCalendars: [SyncedCalendarInfo] {
        let ids = Set(self.compactMap { event in
            if case .calendar(let calendarID) = event.dataSource {
                calendarID
            } else {
                nil
            }
        })
        return ids.map { id in
            let event = self.first(where: { $0.dataSource == .calendar(id: id) })
            return SyncedCalendarInfo(id: id, colorName: event?.colorName, icon: event?.icon)
        }
    }
}
