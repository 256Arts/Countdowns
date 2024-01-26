//
//  Countdowns_WatchApp.swift
//  Countdowns Watch Watch App
//
//  Created by 256 Arts Developer on 2023-09-27.
//

import SwiftUI
import SwiftData

@main
struct Countdowns_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            UpcomingList()
        }
        .modelContainer(for: Event.self)
    }
}
