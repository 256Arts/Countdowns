import SwiftUI

enum Symbol: String, Equatable, Hashable, CaseIterable, Identifiable {
    // Generic
    case calendar
    case music = "music.note"
    case ticket, tv, film, gamecontroller, iphone, gift, shippingbox, leaf, pawprint
    case figure = "figure.arms.open"
    case figurerun = "figure.run"
    case family = "figure.2.and.child.holdinghands"
    case birthdayCake = "birthday.cake"
    
    // Living
    case house, building, car, bus, tram, airplane, sailboat
    case bed = "bed.double"
    
    // Shapes
    case star, heart
    
    static let defaultSymbol = Symbol.calendar

    var id: Self { self }

    /// What VoiceOver reads for the swatch in `SymbolPicker`.
    var displayName: LocalizedStringResource {
        switch self {
        case .calendar: "Calendar"
        case .music: "Music"
        case .ticket: "Ticket"
        case .tv: "TV"
        case .film: "Film"
        case .gamecontroller: "Game Controller"
        case .iphone: "iPhone"
        case .gift: "Gift"
        case .shippingbox: "Package"
        case .leaf: "Leaf"
        case .pawprint: "Paw Print"
        case .figure: "Person"
        case .figurerun: "Running"
        case .family: "Family"
        case .birthdayCake: "Birthday Cake"
        case .house: "House"
        case .building: "Building"
        case .car: "Car"
        case .bus: "Bus"
        case .tram: "Tram"
        case .airplane: "Airplane"
        case .sailboat: "Sailboat"
        case .bed: "Bed"
        case .star: "Star"
        case .heart: "Heart"
        }
    }

}
