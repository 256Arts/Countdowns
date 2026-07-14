import Foundation

enum IconResource: Equatable, Hashable {
    case symbolIcon(name: String)
    case remote(URL)
    case preloaded(Data)
}
