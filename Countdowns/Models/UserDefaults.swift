//
//  UserDefaults.swift
//  Countdowns
//
//  Created by Jayden Irwin on 2025-10-03.
//

import Foundation

extension UserDefaults {
    
    enum Key {
        static let eventDataSourcesAdded = "eventDataSourcesAdded"
    }
    
    func register() {
        register(defaults: [
            Key.eventDataSourcesAdded: 0
        ])
    }
    
    // Tracks how many events the user has added
    var eventDataSourcesAddedCount: Int {
        get { integer(forKey: Key.eventDataSourcesAdded) }
        set { set(newValue, forKey: Key.eventDataSourcesAdded) }
    }
    
    /// Increments the count of events the user has added and returns if the app should request a review
    func incrementEventAddedCount() -> Bool {
        let newValue = eventDataSourcesAddedCount + 1
        set(newValue, forKey: Key.eventDataSourcesAdded)
        return [5, 20, 50, 100].contains(newValue)
    }
    
}
