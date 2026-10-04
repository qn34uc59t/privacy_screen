import SwiftUI

/// Animated pulsing status indicator dot.
struct PulsingDotView: View {
    let color: Color
    let animate: Bool

    @State private var pulsing = false

    var body: some View {
        ZStack {
            // Outer halo ring — pulses outward and fades
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 14, height: 14)
                .scaleEffect(animate && pulsing ? 1.7 : 0.6)
                .opacity(animate && pulsing ? 0 : 0.6)

            // Solid core dot
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
        .onAppear {
            guard animate else { return }
            withAnimation(
                .easeOut(duration: 1.1)
                .repeatForever(autoreverses: false)
            ) {
                pulsing = true
            }
        }
        .onChange(of: animate) { _, newValue in
            if newValue {
                pulsing = false
                withAnimation(
                    .easeOut(duration: 1.1)
                    .repeatForever(autoreverses: false)
                ) {
                    pulsing = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { pulsing = false }
            }
        }
    }
}
