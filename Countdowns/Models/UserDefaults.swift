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
    
    /// Increments the count of events the user has added and returns if the app should request a review
    func incrementEventAddedCount() -> Bool {
        let newValue = integer(forKey: Key.eventDataSourcesAdded) + 1
        set(newValue, forKey: Key.eventDataSourcesAdded)
        return [5, 20, 50, 100].contains(newValue)
    }
    
}
