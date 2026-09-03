import SwiftUI

enum ColorName: String, Codable, CaseIterable, Identifiable {
    case white, gray, black, red, green, blue, yellow, purple, orange
    
    var id: Self { self }
    
    /// What VoiceOver reads for the swatch in `ColorPickerRow`.
    var displayName: LocalizedStringResource {
        switch self {
        case .white: "White"
        case .gray: "Gray"
        case .black: "Black"
        case .red: "Red"
        case .green: "Green"
        case .blue: "Blue"
        case .yellow: "Yellow"
        case .purple: "Purple"
        case .orange: "Orange"
        }
    }

    var color: Color {
        switch self {
        case .white: .white
        case .gray: .gray
        case .black: .black
        case .red: .red
        case .green: .green
        case .blue: .blue
        case .yellow: .yellow
        case .purple: .purple
        case .orange: .orange
        }
    }
}
