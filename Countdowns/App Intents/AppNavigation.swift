//
//  AppNavigation.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2026-06-29.
//

import Foundation
import Observation

/// Shared navigation state the app observes so that App Intents (e.g. "Open my birthday countdown")
/// can drive the UI after launching the app.
@MainActor
@Observable
final class AppNavigation {

    static let shared = AppNavigation()

    private init() { }

    /// The event the app should present. Set by `OpenCountdownIntent` when Siri opens a countdown.
    var selectedEvent: Event?
}
