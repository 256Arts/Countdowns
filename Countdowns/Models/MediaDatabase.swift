//
//  MediaDatabase.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2022-12-08.
//

import Foundation
import TMDb

struct Media: Identifiable {
    let id: Int
    let title: String
    let isMovie: Bool
    let posterURL: URL?
    var releaseDate: Date?
}

final class MediaDatabase {
    
    static let shared = MediaDatabase()
    
    private let api = TMDbAPI(apiKey: "0ff81004cf53396fd20157671a5bd0ab")
    
    func search(_ string: String) async throws -> [Media] {
        guard !string.isEmpty else { return [] }
        
        return try await api.search.searchAll(query: string, page: nil).results.compactMap {
            switch $0 {
            case .movie(let movie):
                guard movie.releaseDate?.timeIntervalSince(.now) ?? 1 > 0 else { return nil }
                
                return Media(id: movie.id, title: movie.title, isMovie: true, posterURL: posterURL(path: movie.posterPath), releaseDate: movie.releaseDate)
            case .tvShow(let tvShow):
                return Media(id: tvShow.id, title: tvShow.name, isMovie: false, posterURL: posterURL(path: tvShow.posterPath), releaseDate: nil)
            default:
                return nil
            }
        }
    }
    
    func fetchMovieReleaseDate(id: Int) async throws -> (Date?, URL?) {
        let movie = try await api.movies.details(forMovie: id)
        return (movie.releaseDate, posterURL(path: movie.posterPath))
    }
    
    func fetchTVShowReleaseDate(id: Int) async throws -> (Date?, URL?) {
        let tvShow = try await api.tvShows.details(forTVShow: id)
        let date = tvShow.seasons?.max(by: { $0.seasonNumber < $1.seasonNumber })?.airDate
        return (date, posterURL(path: tvShow.posterPath))
    }
    
    private func posterURL(path: URL?) -> URL? {
        if let suffix = path?.absoluteString {
            return URL(string: "https://image.tmdb.org/t/p/w185/" + suffix)
        } else {
            return nil
        }
    }
    
}
