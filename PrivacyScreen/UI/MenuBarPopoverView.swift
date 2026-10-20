import SwiftUI

struct MenuBarPopoverView: View {
    @Bindable var motionState: MotionState
    var onCalibrate: () -> Void

    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Privacy Screen row — dot replaces icon, conveys state via color
                HStack(spacing: 10) {
                    let (color, animated) = dotState
                    PulsingDotView(color: color, animate: animated)
                        .frame(width: 16, alignment: .center)

                    Text("Privacy Screen")
                        .font(.system(size: 13))

                    Spacer()

                    Toggle("", isOn: $motionState.isActive)
                        .toggleStyle(.switch)
                        .tint(Color(red: 0, green: 0.83, blue: 0.78))
                        .labelsHidden()
                        .controlSize(.small)
                        .onChange(of: motionState.isActive) { _, newValue in
                            if newValue { motionState.startTracking() } else { motionState.stopTracking() }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().padding(.leading, 40)

                // Instant Lock row
                MenuRow(icon: "lock", label: "Instant Lock", binding: $motionState.isParanoiaModeEnabled)

                Divider()

                // Calibration button
                Button(action: onCalibrate) {
                    Label("Open Calibration Panel", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(MenuActionButtonStyle())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()

                // Footer
                HStack {
                    Toggle("Launch at Login", isOn: $motionState.launchAtLogin)
                        .toggleStyle(.checkbox)

                    Spacer()

                    Button("Quit") { NSApp.terminate(nil) }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 280)
    }

    private var dotState: (Color, Bool) {
        if !motionState.isAvailable && motionState.lastError != nil {
            return (.red, false)
        } else if !motionState.isActive {
            return (.secondary, false)
        } else if motionState.isTriggered {
            return (.red, true)
        } else {
            return (Color(red: 0, green: 0.83, blue: 0.78), true)
        }
    }
}

// MARK: - Menu Row

private struct MenuRow: View {
    let icon: String
    let label: String
    let binding: Binding<Bool>

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 16, alignment: .center)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .tint(Color(red: 0, green: 0.83, blue: 0.78))
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Menu Action Button

private struct MenuActionButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .onHover { isHovered = $0 }
    }
}

// MARK: - Visual Effect

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
