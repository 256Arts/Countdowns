import Foundation
import Testing
@testable import Countdowns

struct PosterSizeTests {

    @Test func `A stored poster resizes to each width`() throws {
        let stored = try #require(PosterSize.list.url(path: "/abc.jpg"))
        #expect(stored.poster(size: .large).absoluteString == "https://image.tmdb.org/t/p/w500//abc.jpg")
        #expect(stored.poster(size: .thumbnail).absoluteString == "https://image.tmdb.org/t/p/w92//abc.jpg")
        #expect(stored.poster(size: .list) == stored)
    }

    @Test func `A URL that isn't a stored poster comes back unchanged`() throws {
        let url = try #require(URL(string: "https://example.com/w500/abc.jpg"))
        #expect(url.poster(size: .thumbnail) == url)
    }
}
