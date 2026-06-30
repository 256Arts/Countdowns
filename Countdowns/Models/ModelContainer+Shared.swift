//
//  ModelContainer+Shared.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2026-06-29.
//

import SwiftData

extension ModelContainer {

    /// The app's single SwiftData + CloudKit container.
    ///
    /// The SwiftUI app and the App Intents both resolve through this same instance so that events
    /// created or edited via Siri/Shortcuts appear immediately in the running app, and vice versa.
    static let shared: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.256arts.countdowns"))
            return try ModelContainer(for: Event.self, configurations: configuration)
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}
