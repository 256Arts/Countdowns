//
//  EventSource.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import Foundation
import SwiftData

@Model
final class Event: Equatable {
    
    /// Used to update the event date
    enum DataSource: Equatable, Codable {
        case recurrence(month: Int, day: Int, end: Date?)
        case movie(id: Int)
        case tvShow(id: Int)
    }
    
    var dataSource: DataSource?
    var title: String? //= ""
    var colorHEX: String?
    var iconURL: String?
    
    var date: Date?
    var dateIsEstimate: Bool? //= false
    
    init(dataSource: DataSource?, title: String, colorHEX: String?, icon: IconResource, date: Date?, dateIsEstimate: Bool?) {
        self.dataSource = dataSource
        self.title = title
        self.colorHEX = colorHEX
        self.date = date
        self.dateIsEstimate = dateIsEstimate
        
        switch icon {
        case .preloaded(let data):
            preloadedIconData = data
        case .remote(let url):
            iconURL = url.absoluteString
        case .symbolIcon(name: let name):
            iconURL = name
        }
    }
    
    /// DO NOT USE - For SwiftData only (is this needed?)
    init(dataSource: DataSource?, title: String, colorHEX: String?, iconURL: String?, date: Date?, dateIsEstimate: Bool?) {
        self.dataSource = dataSource
        self.title = title
        self.colorHEX = colorHEX
        self.iconURL = iconURL
        self.date = date
        self.dateIsEstimate = dateIsEstimate
    }
    
    @Transient
    var preloadedIconData: Data?
    
    @Transient
    var icon: IconResource? {
        if let preloadedIconData {
            return .preloaded(preloadedIconData)
        } else {
            let urlString = iconURL ?? Symbol.defaultSymbol.rawValue
            if urlString.contains("/"), let url = URL(string: urlString) {
                return .remote(url)
            } else {
                return .symbolIcon(name: urlString)
            }
        }
    }
    
    @Transient
    var subtitle: String {
        switch dataSource {
        case .recurrence(let month, let day, _):
            if month == 2, day == 29 {
                return "Every ~4 years on \(DateFormatter().monthSymbols[month-1]) \(day)"
            } else {
                return "Yearly on \(DateFormatter().monthSymbols[month-1]) \(day)"
            }
        case .movie, .tvShow:
            return "From the Web"
        case nil:
            return "Single Event"
        }
    }
    
    @Transient
    var daysUntil: Int? {
        if let date {
            let calendar = Calendar.autoupdatingCurrent
            return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: date).day
        } else {
            return nil
        }
    }
    
    @Transient
    var daysUntilString: String {
        if let daysUntil {
            return ((dateIsEstimate ?? false) ? "~" : "") + String(daysUntil)
        } else {
            return ""
        }
    }
    
    /// Whether the estimated date will be replaced by a server value when it becomes available
    @Transient
    var isTemporaryEstimate: Bool {
        guard dateIsEstimate == true else { return false }
        
        switch dataSource {
        case .recurrence:
            return false
        default:
            return true
        }
    }
    
    @Transient
    var relevanceScore: Int {
        // Note: Do not sort by this value, since 30+ days would all share the same sort position
        
        // -1 days away = 0 score
        //  0 days away = 31 score
        //  1 days away = 30 score
        // 30 days away = 1 score
        // 31 days away = 1 score
        if let daysUntil, 0 < daysUntil {
            return max(1, 31 - daysUntil)
        } else {
            return 0
        }
    }
    
    @Transient
    var isEditable: Bool {
        switch dataSource {
        case .movie, .tvShow:
            return false
        default:
            return true
        }
    }
    
    func preloadImage(large: Bool) async throws {
        if case .remote(let url) = icon {
            let sizedURL = URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: large ? "/w500/" : "/w92/"))!
            preloadedIconData = try await URLSession.shared.data(from: sizedURL).0
        }
    }
    
    func fetch() async {
        switch dataSource {
        case .recurrence(let month, let day, let endDate):
            if let daysUntil {
                guard daysUntil < 0 else { return }
            }
            
            let year: Int = {
                let today = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: .now)
                var year: Int = {
                    if today.month! < month || (today.month == month && today.day! < day) {
                        return today.year!
                    } else {
                        return today.year! + 1
                    }
                }()
                if month == 2, day == 29 {
                    // Leap day
                    while year % 4 != 0 && (year % 100 == 0 || year % 400 != 0) {
                        year += 1
                    }
                }
                return year
            }()
            let nextDate = Calendar.autoupdatingCurrent.date(from: DateComponents(year: year, month: month, day: day))
            self.date = (nextDate ?? .now) < (endDate ?? .distantFuture) ? nextDate : nil
        case .movie(let id):
            if let result = try? await MediaDatabase.shared.fetchMovieReleaseDate(id: id), let date = result.0 {
                self.iconURL = result.1?.absoluteString ?? "film"
                self.date = date
                self.dateIsEstimate = false
            }
        case .tvShow(let id):
            if let result = try? await MediaDatabase.shared.fetchTVShowReleaseDate(id: id), let date = result.0 {
                self.iconURL = result.1?.absoluteString ?? "tv"
                self.date = date
                self.dateIsEstimate = false
            }
        case nil:
            break
        }
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        if let lhsDataSource = lhs.dataSource {
            return lhsDataSource == rhs.dataSource && lhs.title == rhs.title
        } else {
            return lhs.title == rhs.title && lhs.date == rhs.date
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension [Event] {
    var upcoming: [Event] {
        filter({ $0.relevanceScore > 0 }).sorted(by: { $0.daysUntil ?? .max < $1.daysUntil ?? .max })
    }
}
