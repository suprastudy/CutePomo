import SwiftUI

struct ShapeSelectorView: View {
    enum ShapeStyle: String, CaseIterable {
        case rounded = "< Rounded >"
        case monospaced = "< Monospaced >"

        mutating func toggle() {
            self = ShapeStyle.allCases.first(where: { $0 != self })!
        }
    }

    @Binding var isMonospaced: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentShape: ShapeStyle {
        isMonospaced ? .monospaced : .rounded
    }
    
    private var backgroundOpacity: Double {
        colorScheme == .dark ? 0.15 : 0.08
    }
    
    private var borderOpacity: Double {
        colorScheme == .dark ? 0.4 : 0.25
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                isMonospaced.toggle()
            }) {
                HStack {
                    Text("Style")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(currentShape.rawValue)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.7 : 0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(borderOpacity), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 0)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShapeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ShapeSelectorView(isMonospaced: .constant(false))
            .preferredColorScheme(.dark)
    }
}
