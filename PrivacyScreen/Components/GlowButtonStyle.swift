import SwiftUI

struct GlowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverableButtonView(
            configuration: configuration,
            defaultColor: Color(red: 0, green: 0.35, blue: 0.35),
            hoverColor: Color(red: 0, green: 0.45, blue: 0.45)
        )
    }
}

struct BlackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverableButtonView(
            configuration: configuration,
            defaultColor: Color(white: 0.08),
            hoverColor: Color(white: 0.12)
        )
    }
}

private struct HoverableButtonView: View {
    let configuration: ButtonStyle.Configuration
    let defaultColor: Color
    let hoverColor: Color
    
    @State private var isHovered = false
    
    var body: some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? hoverColor : defaultColor)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
