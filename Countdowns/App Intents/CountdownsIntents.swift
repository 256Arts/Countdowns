import AppIntents
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

enum CountdownsIntentError: Error, CustomLocalizedStringResourceConvertible {
    case eventNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .eventNotFound: "Couldn't find that event."
        }
    }
}

/// Creates a new countdown. Runs in-app without opening it, so Siri can add events hands-free.
struct CreateCountdownIntent: AppIntent {

    static let title: LocalizedStringResource = "Create Countdown"
    static let description = IntentDescription("Creates a new countdown to a date.", categoryName: "Events")

    @Parameter(title: "Title", requestValueDialog: "What are you counting down to?")
    var eventTitle: String

    @Parameter(title: "Date", kind: .date, requestValueDialog: "What's the date?")
    var date: Date

    @Parameter(title: "Repeat Yearly", default: false)
    var repeatsYearly: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Create a countdown to \(\.$eventTitle) on \(\.$date)") {
            \.$repeatsYearly
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<EventEntity> & ProvidesDialog {
        let dayComponents = Calendar.autoupdatingCurrent.dateComponents([.month, .day], from: date)
        let dataSource: Event.DataSource? = repeatsYearly
            ? .recurrence(month: dayComponents.month!, day: dayComponents.day!, end: nil)
            : nil
        let event = Event(
            dataSource: dataSource,
            title: eventTitle,
            colorName: nil,
            icon: .symbolIcon(name: Symbol.defaultSymbol.rawValue),
            date: date,
            dateIsEstimate: false)

        let context = EventStore.context
        context.insert(event)
        await event.fetch()
        try context.save()

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif

        return .result(value: EventEntity(event), dialog: "Added “\(eventTitle)” to your countdowns.")
    }
}

/// Speaks/returns how many days remain until an event.
struct DaysUntilCountdownIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Days Until Event"
    static let description = IntentDescription("Gets the number of days until a countdown event.", categoryName: "Events")

    @Parameter(title: "Event")
    var target: EventEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get days until \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        guard let event = try EventStore.event(id: target.id), let days = event.daysUntil else {
            throw CountdownsIntentError.eventNotFound
        }
        let dialog: IntentDialog = switch days {
        case ..<0: "\(target.title) was \(-days) days ago."
        case 0: "\(target.title) is today!"
        case 1: "\(target.title) is tomorrow."
        default: "\(days) days until \(target.title)."
        }
        return .result(value: days, dialog: dialog)
    }
}

/// Returns the soonest upcoming events.
struct UpcomingCountdownsIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Upcoming Events"
    static let description = IntentDescription("Gets your upcoming countdown events, soonest first.", categoryName: "Events")

    @Parameter(title: "Limit", default: 5)
    var limit: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Get the next \(\.$limit) upcoming events")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[EventEntity]> & ProvidesDialog {
        let events = Array(try EventStore.upcomingEntities().prefix(max(1, limit)))
        let dialog: IntentDialog = if let next = events.first {
            "Your next event is \(next.title)."
        } else {
            "You have no upcoming events."
        }
        return .result(value: events, dialog: dialog)
    }
}

/// Opens a specific countdown in the app.
struct OpenCountdownIntent: OpenIntent {

    static let title: LocalizedStringResource = "Open Countdown"
    static let description = IntentDescription("Opens a countdown in Countdowns.", categoryName: "Events")

    @Parameter(title: "Event")
    var target: EventEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppNavigation.shared.selectedEvent = try EventStore.event(id: target.id)
        return .result()
    }
}
