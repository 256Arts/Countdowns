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
    #else
    let itemSize: CGFloat = 40
    let symbolFontSize: CGFloat = 18
    #endif
    
    @Binding var selected: Symbol
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemSize + 4, maximum: itemSize + 6))], spacing: 12) {
            ForEach(Symbol.allCases) { symbol in
                ZStack {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    Image(systemName: symbol.rawValue)
                }
                .frame(height: itemSize)
                .overlay {
                    if symbol == selected {
                        Circle()
                            .stroke(Color(UIColor.tertiaryLabel), lineWidth: 2.5)
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

struct SymbolPicker_Previews: PreviewProvider {
    static var previews: some View {
        SymbolPicker(selected: .constant(Symbol.defaultSymbol))
    }
}
