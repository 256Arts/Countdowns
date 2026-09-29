import Foundation

enum IconResource: Equatable, Hashable {
    case symbolIcon(name: String)
    case remote(URL)
    case preloaded(Data)
}

/// TMDB poster widths. Posters are stored at `list` size; the other sizes are made by swapping that path segment.
enum PosterSize: String {
    case thumbnail = "w92"
    case list = "w185"
    case large = "w500"
    
    func url(path: String) -> URL? {
        URL(string: "https://image.tmdb.org/t/p/\(rawValue)/" + path)
    }
}

extension URL {
    /// This TMDB poster at another size. URLs that aren't stored posters come back unchanged.
    func poster(size: PosterSize) -> URL {
        URL(string: absoluteString.replacingOccurrences(of: "/\(PosterSize.list.rawValue)/", with: "/\(size.rawValue)/")) ?? self
    }
}
