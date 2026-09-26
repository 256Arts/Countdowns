import Foundation
import UserNotifications

/// Schedules a local notification on the morning of each upcoming event, and optionally the morning before.
enum NotificationScheduler {

    /// The hour of the day notifications are delivered.
    static let deliveryHour = 9

    /// iOS keeps at most this many pending requests and silently drops the rest, so only the soonest are scheduled.
    static let pendingLimit = 64

    /// A snapshot of everything a schedule depends on, so the list can reschedule only when one of these changes.
    struct Plan: Hashable {
        struct Occasion: Hashable {
            var title: String
            var date: Date
            var isEstimate: Bool
        }

        var occasions: [Occasion]
        var onEventDay: Bool
        var dayBefore: Bool

        init(events: [Event], onEventDay: Bool, dayBefore: Bool) {
            self.onEventDay = onEventDay
            self.dayBefore = dayBefore
            // Nothing to deliver, so skip the snapshot and let the plan stay equal while events change.
            occasions = onEventDay ? events.compactMap { event in
                guard let date = event.date else { return nil }
                return Occasion(title: event.title ?? "", date: date, isEstimate: event.dateIsEstimate ?? false)
            } : []
        }
    }

    /// Replaces every pending notification with the ones `plan` calls for.
    static func reschedule(_ plan: Plan) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard plan.onEventDay else { return }

        for request in requests(for: plan, after: .now) {
            try? await center.add(request)
        }
    }

    /// Asks for permission to alert, returning whether it was granted.
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    private static func requests(for plan: Plan, after now: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.autoupdatingCurrent
        var alerts: [(fireDate: Date, content: UNNotificationContent)] = []

        for occasion in plan.occasions {
            let eventDay = calendar.startOfDay(for: occasion.date)
            if let fireDate = calendar.date(bySettingHour: deliveryHour, minute: 0, second: 0, of: eventDay) {
                alerts.append((fireDate, content(for: occasion, isDayBefore: false)))
            }
            if plan.dayBefore,
               let dayBefore = calendar.date(byAdding: .day, value: -1, to: eventDay),
               let fireDate = calendar.date(bySettingHour: deliveryHour, minute: 0, second: 0, of: dayBefore) {
                alerts.append((fireDate, content(for: occasion, isDayBefore: true)))
            }
        }

        return alerts
            .filter { now < $0.fireDate }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(pendingLimit)
            .enumerated()
            .map { index, alert in
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alert.fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                return UNNotificationRequest(identifier: "countdown-\(index)", content: alert.content, trigger: trigger)
            }
    }

    private static func content(for occasion: Plan.Occasion, isDayBefore: Bool) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = occasion.title
        content.body = switch (isDayBefore, occasion.isEstimate) {
        case (false, false): String(localized: "Today")
        case (false, true): String(localized: "Expected today")
        case (true, false): String(localized: "Tomorrow")
        case (true, true): String(localized: "Expected tomorrow")
        }
        content.sound = .default
        return content
    }

}
