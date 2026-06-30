//
//  EventDateSuggester.swift
//  Countdowns
//
//  Created by Claude on 2026-06-26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Uses Apple Intelligence to guess the next upcoming date, color, and icon for a well-known
/// event title.
///
/// Prefers Apple's Private Cloud Compute model (iOS/macOS 27+) for better recall on less common
/// events, and falls back to the on-device system model when the cloud model isn't available.
enum EventDateSuggester {

    /// A complete suggestion offered to the user for a recognized event.
    struct Suggestion {
        /// The event's proper, canonical name (e.g. "Christmas Day"), not the user's raw input.
        let title: String
        let date: Date
        /// True when the event recurs on the same date every year (most holidays and observances).
        let repeatsYearly: Bool
        let colorName: ColorName?
        let symbol: Symbol?
    }

    #if canImport(FoundationModels)
    @Generable
    struct Generated {
        @Guide(description: "True only if the title clearly names a well-known event with a predictable date (holiday, observance, conference, product launch, sporting final, etc.). False for personal, vague, or made-up titles.")
        var isKnownEvent: Bool

        @Guide(description: "True if the title the user typed is already an acceptable, recognizable name for this event on its own, including well-known acronyms or abbreviations (e.g. 'WWDC', 'NYE', 'July 4th'). False only if it is a partial fragment, misspelled, or merely a description that should be replaced with the proper name (e.g. 'apple world wide developer', 'xmas').")
        var userTitleIsComplete: Bool

        @Guide(description: "The event's proper, canonical name, spelled and capitalized correctly. Used only when the user's typed title is incomplete. Correct typos, expand abbreviations, and use the commonly recognized name (e.g. 'xmas' becomes 'Christmas Day').")
        var title: String

        @Guide(description: "True if this event recurs on the same calendar date every year (most holidays and observances). False for one-off events like a specific conference, product launch, or sporting final.")
        var repeatsYearly: Bool

        @Guide(description: "Year of the next occurrence on or after today")
        var year: Int

        @Guide(description: "Month of the next occurrence, from 1 to 12")
        var month: Int

        @Guide(description: "Day of the month of the next occurrence, from 1 to 31")
        var day: Int

        @Guide(description: "The color that best represents this event", .anyOf(ColorName.allCases.map(\.rawValue)))
        var colorName: String

        @Guide(description: "The icon that best represents this event", .anyOf(Symbol.allCases.map(\.rawValue)))
        var symbol: String
    }
    #endif

    /// Whether suggestions are currently available on this device (cloud or on-device).
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if PrivateCloudComputeLanguageModel().isAvailable {
            return true
        }
        return SystemLanguageModel.default.isAvailable
        #else
        return false
        #endif
    }

    /// Returns a suggested date, color, and icon for the given event title, or `nil` if the
    /// title isn't a recognizable event, no model is available, or the guessed date isn't
    /// in the future.
    static func suggestion(for title: String) async -> Suggestion? {
        #if canImport(FoundationModels)
        let today = Date.now.formatted(.dateTime.year().month(.wide).day())
        let instructions = """
            You identify well-known upcoming events from a short title typed by the user, and pick a fitting color and icon for each.
            The title may be incomplete, since the user is still typing it. Only set isKnownEvent to true once enough has been typed to unambiguously identify a single well-known event; while the input is still a partial fragment that could begin many different titles, set isKnownEvent to false.
            Today is \(today). Always return the next occurrence that falls on or after today.
            If the title does not clearly refer to a well-known event with a predictable date, set isKnownEvent to false.
            """
        guard let session = makeSession(instructions: instructions) else { return nil }

        do {
            let generated = try await session.respond(to: "Event title: \"\(title)\"", generating: Generated.self).content
            guard generated.isKnownEvent else { return nil }
            // Keep the user's own title when it's already a complete name; only fall back to the
            // model's canonical name when the typed input is a fragment or misspelling.
            let canonicalTitle = generated.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let suggestedTitle = generated.userTitleIsComplete || canonicalTitle.isEmpty ? title : canonicalTitle
            let calendar = Calendar.autoupdatingCurrent
            let components = DateComponents(year: generated.year, month: generated.month, day: generated.day)
            guard let date = calendar.date(from: components) else { return nil }
            // Reject dates the model placed in the past.
            guard calendar.startOfDay(for: date) >= calendar.startOfDay(for: .now) else { return nil }
            return Suggestion(
                title: suggestedTitle,
                date: date,
                repeatsYearly: generated.repeatsYearly,
                colorName: ColorName(rawValue: generated.colorName),
                symbol: Symbol(rawValue: generated.symbol)
            )
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    #if canImport(FoundationModels)
    /// Builds a session on Apple's Private Cloud Compute model when available, otherwise on the
    /// on-device model. Returns `nil` if neither is available.
    private static func makeSession(instructions: String) -> LanguageModelSession? {
        let cloud = PrivateCloudComputeLanguageModel()
        if cloud.isAvailable {
            return LanguageModelSession(model: cloud) { instructions }
        }
        guard SystemLanguageModel.default.isAvailable else { return nil }
        // Omit `model:` so the default-system-model initializer is chosen unambiguously
        // (passing `SystemLanguageModel.default` also matches the generic `init(model:)`).
        return LanguageModelSession { instructions }
    }
    #endif
}
