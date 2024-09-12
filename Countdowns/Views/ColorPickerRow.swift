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

    @Binding var selected: ColorName?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemSize + 4, maximum: itemSize + 6))], spacing: 12) {
            ForEach(ColorName.allCases) { colorName in
                ZStack {
                    Circle()
                        .fill(colorName.color)
                }
                .frame(height: itemSize)
                .overlay {
                    if colorName == selected {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2.5)
                            .padding(-5)
                    }
                }
                .onTapGesture {
                    selected = colorName
                }
            }
        }
        .padding(.horizontal, -4)
        .padding(.vertical, 12)
    }
}

#Preview {
    ColorPickerRow(selected: .constant(.blue))
}
