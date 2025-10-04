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
    
    func fetchUpcomingEvents(calendar: EKCalendar, endDate: Date) -> [EKEvent] {
        guard isFullAccessAuthorized else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: .now, end: endDate, calendars: [calendar])
        return eventStore.events(matching: predicate)
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
            await store.allCalendars
        }
    }
    
    func generateUpcomingEvents(calendarID: String, colorName: ColorName?, icon: IconResource?) async throws -> [Event] {
        guard let calendar = await store.calendar(withIdentifier: calendarID) else { throw ServiceError.calendarNotFound }
        
        let endDate = Date.now.addingTimeInterval(3 * 365 * 24 * 60 * 60)
        return await store.fetchUpcomingEvents(calendar: calendar, endDate: endDate).map { event in
            Event(
                dataSource: .calendar(id: calendar.calendarIdentifier),
                title: event.title,
                colorName: colorName,
                icon: icon,
                date: event.startDate,
                dateIsEstimate: false
            )
        }
    }
    
    func regenerateCalendarEvents(modelContext: ModelContext, allEvents: [Event]) async {
        guard !isUpdatingCalendarEvents else { return }
        
        isUpdatingCalendarEvents = true
        for info in allEvents.syncedCalendars {
            do {
                let oldEvents = allEvents.filter { $0.dataSource == .calendar(id: info.id) }
                for oldEvent in oldEvents {
                    modelContext.delete(oldEvent)
                }
                let newEvents = try await generateUpcomingEvents(
                    calendarID: info.id,
                    colorName: info.colorName,
                    icon: info.icon
                )
                for newEvent in newEvents {
                    modelContext.insert(newEvent)
                }
            } catch { }
        }
        isUpdatingCalendarEvents = false
    }
    
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
