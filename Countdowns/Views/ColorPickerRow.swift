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
                // A tap gesture on a bare circle is invisible to VoiceOver, so each swatch has to
                // say which colour it is and that it can be picked.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(colorName.displayName))
                .accessibilityIdentifier("Color.\(colorName.rawValue)")
                .accessibilityAddTraits(colorName == selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, -4)
        .padding(.vertical, 12)
    }
}

#Preview {
    ColorPickerRow(selected: .constant(.blue))
}
