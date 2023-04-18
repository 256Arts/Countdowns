//
//  CloudController.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-12-07.
//

import Foundation

final class CloudController: ObservableObject {
    
    enum FetchError: Error {
        case noObjectForKey
    }
    
    static let shared = CloudController()
    
    let filename = "Events Data.json"
    var fileURL: URL {
        let directoryURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directoryURL.appending(path: filename, directoryHint: .notDirectory)
    }
    
    let finishGatheringQuery = NSMetadataQuery()
    let updateQuery = NSMetadataQuery()

    @Published var eventsData: EventsData?
    @Published var decodeError: Error?
    
    init() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(queryDidFinishGathering),
            name: Notification.Name.NSMetadataQueryDidFinishGathering,
            object: finishGatheringQuery)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidUpdate),
            name: NSNotification.Name.NSMetadataQueryDidUpdate,
            object: updateQuery)
        
        finishGatheringQuery.notificationBatchingInterval = 1
        finishGatheringQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        finishGatheringQuery.predicate = NSPredicate(format: "%K LIKE '\(filename)'", NSMetadataItemFSNameKey)
        finishGatheringQuery.start()
        
        updateQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        updateQuery.valueListAttributes = [NSMetadataUbiquitousItemPercentDownloadedKey, NSMetadataUbiquitousItemDownloadingStatusKey]
        updateQuery.predicate = NSPredicate(format: "%K LIKE '\(filename)'", NSMetadataItemFSNameKey)
        updateQuery.start()
    }

    @objc func queryDidFinishGathering(_ notification: Notification) {
        finishGatheringQuery.disableUpdates()
        Task { @MainActor in
            if finishGatheringQuery.results.isEmpty {
                print("No cloud files found. Creating new file.")
                eventsData = EventsData(fileVersion: EventsData.newestFileVersion)
            } else {
                do {
                    eventsData = try await fetchEventsData()
                } catch {
                    decodeError = error
                    print("Failed to fetch data after query gather")
                }
            }
            finishGatheringQuery.enableUpdates()
        }
    }
    
    @objc func queryDidUpdate(_ notification: Notification) {
        updateQuery.disableUpdates()
        Task { @MainActor in
            if updateQuery.results.isEmpty {
                print("No cloud files found. Creating new file.")
                eventsData = EventsData(fileVersion: EventsData.newestFileVersion)
            } else {
                do {
                    eventsData = try await fetchEventsData()
                } catch {
                    decodeError = error
                    print("Failed to fetch data after query gather")
                }
            }
            updateQuery.enableUpdates()
        }
    }
    
    func fetchEventsData() async throws -> EventsData? {
        try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
        let attributes = try fileURL.resourceValues(forKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey])
        if let status: URLUbiquitousItemDownloadingStatus = attributes.allValues[URLResourceKey.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus {
            switch status {
            case .current, .downloaded:
                let savedData = try Data(contentsOf: fileURL)
                return try loadEventsData(data: savedData)
            default:
                #if os(macOS)
                return nil // Bug workaround
                #else
                // Download again
                try await Task.sleep(for: .seconds(0.1))
                return try await fetchEventsData()
                #endif
            }
        }

        let savedData = try Data(contentsOf: fileURL)
        return try loadEventsData(data: savedData)
    }

    func loadEventsData(data: Data) throws -> EventsData {
        // Upgrade data here if needed
        return try JSONDecoder().decode(EventsData.self, from: data)
    }
    
}
