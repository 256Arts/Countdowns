//
//  ColorPickerRow.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-03-28.
//

import SwiftUI

struct ColorPickerRow: View {
    
    #if os(macOS)
    let itemSize: CGFloat = 30
    #else
    let itemSize: CGFloat = 40
    #endif
    
    let allColors: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .pink, .purple, .brown, .gray]

    @Binding var selected: Color
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemSize + 4, maximum: itemSize + 6))], spacing: 12) {
            ForEach(allColors) { color in
                ZStack {
                    Circle()
                        .fill(color)
                }
                .frame(height: itemSize)
                .overlay {
                    if color == selected {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2.5)
                            .padding(-5)
                    }
                }
                .onTapGesture {
                    selected = color
                }
            }
        }
        .padding(.horizontal, -4)
        .padding(.vertical, 12)
    }
}

extension Color: Identifiable {
    public var id: String { description }
}

struct ColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerRow(selected: .constant(.blue))
    }
}
