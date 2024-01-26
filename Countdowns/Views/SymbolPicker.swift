//
//  SymbolPicker.swift
//  Countdowns
//
//  Created by 256 Arts Developer on 2023-03-02.
//

import SwiftUI

struct SymbolPicker: View {
    
    #if os(macOS)
    let itemSize: CGFloat = 30
    let symbolFontSize: CGFloat = 14
    let itemBackground: NSColor = .controlBackgroundColor
    let selectedItemOutline: NSColor = .tertiaryLabelColor
    #else
    let itemSize: CGFloat = 40
    let symbolFontSize: CGFloat = 18
    let itemBackground: UIColor = .tertiarySystemGroupedBackground
    let selectedItemOutline: UIColor = .tertiaryLabel
    #endif
    
    @Binding var selected: Symbol
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemSize + 4, maximum: itemSize + 6))], spacing: 12) {
            ForEach(Symbol.allCases) { symbol in
                ZStack {
                    Circle()
                        .fill(Color(itemBackground))
                    Image(systemName: symbol.rawValue)
                }
                .frame(height: itemSize)
                .overlay {
                    if symbol == selected {
                        Circle()
                            .stroke(Color(selectedItemOutline), lineWidth: 2.5)
                            .padding(-5)
                    }
                }
                .onTapGesture {
                    selected = symbol
                }
            }
        }
        .symbolVariant(.fill)
        .font(.system(size: symbolFontSize, weight: .medium))
        .foregroundColor(Color.primary)
        .padding(.horizontal, -4)
        .padding(.vertical, 12)
    }
}

#Preview {
    SymbolPicker(selected: .constant(Symbol.defaultSymbol))
}
