import SwiftUI

struct ArcGaugeView: View {
    let label: String
    let value: Double     // Current delta in radians
    let maxRange: Double  // Threshold to max out the gauge

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background track arc
                ArcShape(startAngle: .degrees(135), endAngle: .degrees(45))
                    .stroke(Color(white: 0.2), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)

                // Filled value arc
                let progress = max(-1.0, min(1.0, value / maxRange))
                // Convert progress (-1 to 1) to angle along the 270 degree span
                // Center is at 270 (straight up)
                let centerAngle: Double = 270
                let totalSpan: Double = 270 // From 135 to 45 (wrapping around 360) -> 135 to 360 is 225, 360 to 45 is 45. 225+45 = 270.
                let halfSpan = totalSpan / 2
                
                let targetAngle = centerAngle + (progress * halfSpan)
                
                let start = progress < 0 ? targetAngle : centerAngle
                let end = progress < 0 ? centerAngle : targetAngle
                
                ArcShape(startAngle: .degrees(start), endAngle: .degrees(end))
                    .stroke(Color(red: 0, green: 0.83, blue: 0.78), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(red: 0, green: 0.83, blue: 0.78).opacity(0.5), radius: 4)
                
                // Readout text inside
                let degrees = value * 180 / .pi
                Text(String(format: "%.1f°", degrees))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(height: 80, alignment: .top) // Clip bottom empty space
            
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)
        }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}
