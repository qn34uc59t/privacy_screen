import SwiftUI

struct MenuBarPopoverView: View {
    @Bindable var motionState: MotionState
    var onCalibrate: () -> Void

    var body: some View {
        ZStack {
            // macOS Vibrant background
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // Subtle dark overlay to match the premium dark design
            Color(nsColor: NSColor(white: 0.05, alpha: 0.4))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Row
                HStack {
                    Image(systemName: "eye")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("Privacy Screen")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $motionState.isActive)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0, green: 0.83, blue: 0.78)))
                        .labelsHidden()
                        .onChange(of: motionState.isActive) { _, newValue in
                            if newValue {
                                motionState.startTracking()
                            } else {
                                motionState.stopTracking()
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
                
                // Instant Lock Row
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("Instant Lock")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $motionState.isParanoiaModeEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0, green: 0.83, blue: 0.78)))
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

                // Status Row
                HStack(spacing: 8) {
                    let (statusText, dotColor, isAnimated) = statusInfo
                    
                    PulsingDotView(color: dotColor, animate: isAnimated)
                    
                    Text(statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Spacer()
                    
                    if let start = motionState.trackingStartedAt, motionState.isActive {
                        Text("Since \(start.formatted(.relative(presentation: .numeric)))")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().overlay(Color.white.opacity(0.1))

                // Data Cards
                HStack(spacing: 12) {
                    StatCard(label: "Yaw", value: motionState.deltaYaw)
                    StatCard(label: "Pitch", value: motionState.deltaPitch)
                }
                .padding(16)

                Divider().overlay(Color.white.opacity(0.1))

                // Calibrate CTA
                Button(action: {
                    onCalibrate()
                }) {
                    Text("OPEN CALIBRATION PANEL")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(BlackButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                // Footer
                HStack(spacing: 12) {
                    Toggle("Launch at Login", isOn: Bindable(motionState).launchAtLogin)
                        .toggleStyle(.switch)
                        .tint(Color(red: 0, green: 0.83, blue: 0.78))
                        .foregroundStyle(.white.opacity(0.8))
                        .font(.system(size: 12))
                    
                    Spacer()
                    
                    Text("|")
                        .foregroundStyle(.white.opacity(0.2))
                    
                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 320)
    }
    
    private var statusInfo: (String, Color, Bool) {
        if !motionState.isAvailable && motionState.lastError != nil {
            return ("No AirPods", Color.red, false)
        } else if !motionState.isActive {
            return ("Paused", Color.gray, false)
        } else if motionState.isTriggered {
            return ("Triggered", Color.red, true)
        } else {
            return ("Monitoring", Color(red: 0, green: 0.83, blue: 0.78), true)
        }
    }
}

// MARK: - Subcomponents

struct StatCard: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            let degrees = value * 180 / .pi
            Text(String(format: "%.1f°", degrees))
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(red: 0, green: 0.83, blue: 0.78))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08))
        )
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
