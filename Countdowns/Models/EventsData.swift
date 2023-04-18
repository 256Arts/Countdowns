//
//  EventsData.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-11-29.
//

import Foundation
import WidgetKit

final class EventsData: ObservableObject, Codable {
    
    static let newestFileVersion = 1
    
    let fileVersion: Int
    
    @Published var events: [Event] {
        didSet {
            save()
        }
    }
    
    var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: .now)
        return events
            .filter({ today <= $0.date ?? .distantPast })
            .sorted(by: { $0.date! < $1.date! })
    }
    
    @MainActor
    func refresh() async {
        print("refresh")
        objectWillChange.send()
        await withTaskGroup(of: Void.self) { group in
            for event in events {
                group.addTask {
                    await event.fetch()
                }
            }
            await group.waitForAll()
        }
        save()
    }
    
    init(fileVersion: Int) {
        self.fileVersion = fileVersion
        self.events = []
    }
    
    enum CodingKeys: String, CodingKey {
        case fileVersion, events
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileVersion = try values.decode(Int.self, forKey: .fileVersion)
        events = try values.decode([Event].self, forKey: .events)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileVersion, forKey: .fileVersion)
        try container.encode(events, forKey: .events)
    }
    
    func save() {
        print("save")
        do {
            let encoded = try JSONEncoder().encode(self)
            try encoded.write(to: CloudController.shared.fileURL, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save")
        }
    }
    
}
