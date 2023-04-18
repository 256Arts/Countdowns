//
//  EventSource.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-07-30.
//

import Foundation

final class Event: ObservableObject, Equatable, Hashable, Identifiable, Codable {
    
    enum DataSource: Codable {
        case recurrence(month: Int, day: Int, end: Date?)
        case movie(id: Int)
        case tvShow(id: Int)
    }
    
    let id: String
    var dataSource: DataSource?
    var title: String
    var colorHEX: String?
    var icon: ImageResource
    var date: Date?
    var dateIsEstimate: Bool
    
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
    
    init(id: String, dataSource: DataSource?, title: String, colorHEX: String?, icon: ImageResource, date: Date?, dateIsEstimate: Bool) {
        self.id = id
        self.dataSource = dataSource
        self.title = title
        self.colorHEX = colorHEX
        self.icon = icon
        self.date = date
        self.dateIsEstimate = dateIsEstimate
    }
    
    var daysUntil: Int? {
        if let date {
            return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: date).day
        } else {
            return nil
        }
    }
    var daysUntilString: String {
        if let daysUntil {
            return (dateIsEstimate ? "~" : "") + String(daysUntil)
        } else {
            return ""
        }
    }
    
    func preloadImage(large: Bool) async throws {
        if case .remote(let url) = icon {
            let sizedURL = URL(string: url.absoluteString.replacingOccurrences(of: "/w185/", with: large ? "/w500/" : "/w92/"))!
            let data = try await URLSession.shared.data(from: sizedURL).0
            icon = .preloaded(data)
        }
    }
    
    func isTemporaryEstimate(eventsData: EventsData) -> Bool {
        guard dateIsEstimate else { return false }
        
        switch dataSource {
        case .recurrence:
            return false
        default:
            return true
        }
    }
    
    func fetch() async {
        switch dataSource {
        case .recurrence(let month, let day, let endDate):
            if let daysUntil {
                guard daysUntil < 0 else { return }
            }
            
            let year: Int = {
                let today = Calendar.current.dateComponents([.year, .month, .day], from: .now)
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
            let nextDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
            self.date = (nextDate ?? .now) < (endDate ?? .distantFuture) ? nextDate : nil
        case .movie(let id):
            if let result = try? await MediaDatabase.shared.fetchMovieReleaseDate(id: id), let date = result.0 {
                self.icon = {
                    if let url = result.1 {
                        return .remote(url)
                    } else {
                        return .symbolIcon(name: "film")
                    }
                }()
                self.date = date
                self.dateIsEstimate = false
            }
        case .tvShow(let id):
            if let result = try? await MediaDatabase.shared.fetchTVShowReleaseDate(id: id), let date = result.0 {
                self.icon = {
                    if let url = result.1 {
                        return .remote(url)
                    } else {
                        return .symbolIcon(name: "tv")
                    }
                }()
                self.date = date
                self.dateIsEstimate = false
            }
        case nil:
            break
        }
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
