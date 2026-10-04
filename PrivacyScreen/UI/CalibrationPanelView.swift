import SwiftUI

struct CalibrationPanelView: View {
    @Bindable var motionState: MotionState
    @State private var showingParanoiaInfo = false

    var body: some View {
        ZStack {
            // Dark panel background with subtle inner glow
            Color(nsColor: NSColor(white: 0.05, alpha: 1.0))
                .ignoresSafeArea()
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(spacing: 0) {
                // Paranoia Mode Toggle
                HStack {
                    Toggle("Instant Lock", isOn: $motionState.isParanoiaModeEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0, green: 0.83, blue: 0.78)))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(motionState.isParanoiaModeEnabled ? Color.white : Color.white.opacity(0.5))
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingParanoiaInfo.toggle()
                        }
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .topLeading) {
                        if showingParanoiaInfo {
                            Text("When enabled, the screen will instantly lock instead of just blurring when you look away.")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(12)
                                .frame(width: 220, alignment: .leading)
                                .background(Color(white: 0.15))
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                                .offset(x: -10, y: 24)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal, 32)
                .zIndex(2)
                
                // 3D Scene
                HeadSceneView(motionState: motionState)
                    .frame(width: 300, height: 300)
                    .padding(.vertical, 32)

                // Arc Gauges
                HStack(spacing: 40) {
                    ArcGaugeView(
                        label: "YAW",
                        value: motionState.deltaYaw,
                        maxRange: motionState.yawThreshold
                    )
                    ArcGaugeView(
                        label: "PITCH",
                        value: motionState.deltaPitch,
                        maxRange: motionState.pitchThreshold
                    )
                }
                .padding(.bottom, 32)

                // Calibration Button & Threshold
                VStack(spacing: 24) {
                    Button(action: {
                        if motionState.isActive {
                            motionState.stopTracking()
                        } else {
                            motionState.startTracking()
                        }
                    }) {
                        Text(motionState.isActive ? "STOP TRACKING" : "CALIBRATE AND START")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 14)
                            .frame(minWidth: 280)
                    }
                    .buttonStyle(GlowButtonStyle())

                    HStack(spacing: 32) {
                        // Yaw Slider
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YAW THRESHOLD: ±\(motionState.yawThreshold, specifier: "%.2f")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                            Slider(value: $motionState.yawThreshold, in: 0.1...1.0)
                                .tint(Color(red: 0, green: 0.83, blue: 0.78))
                        }
                        
                        // Pitch Slider
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PITCH THRESHOLD: ±\(motionState.pitchThreshold, specifier: "%.2f")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                            Slider(value: $motionState.pitchThreshold, in: 0.1...1.0)
                                .tint(Color(red: 0, green: 0.83, blue: 0.78))
                        }
                    }
                    .padding(.horizontal, 48)
                }

                Spacer()
            }
        }
        .frame(width: 520, height: 680)
        .cornerRadius(24) // Match outer border
        .ignoresSafeArea() // Ensure the ZStack fills the entire window, bringing traffic lights inside
    }
}
