import Foundation
import CoreMotion
import ServiceManagement

@Observable
@MainActor
final class MotionState: NSObject, CMHeadphoneMotionManagerDelegate {

    // MARK: - Observable properties (drive all UI)

    var rawYaw: Double = 0
    var rawPitch: Double = 0
    var deltaYaw: Double = 0
    var deltaPitch: Double = 0
    var isAvailable: Bool = false
    var isActive: Bool = false
    var intentToTrack: Bool = false
    var isTriggered: Bool = false
    var yawThreshold: Double = UserDefaults.standard.object(forKey: "yawThreshold") as? Double ?? 0.50 {
        didSet { UserDefaults.standard.set(yawThreshold, forKey: "yawThreshold") }
    }
    var pitchThreshold: Double = UserDefaults.standard.object(forKey: "pitchThreshold") as? Double ?? 0.50 {
        didSet { UserDefaults.standard.set(pitchThreshold, forKey: "pitchThreshold") }
    }
    
    var isParanoiaModeEnabled: Bool = UserDefaults.standard.object(forKey: "isParanoiaModeEnabled") as? Bool ?? false {
        didSet { UserDefaults.standard.set(isParanoiaModeEnabled, forKey: "isParanoiaModeEnabled") }
    }
    
    // Auto-launch
    var launchAtLogin: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return false
            }
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                        }
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to update Launch at Login: \(error)")
                }
            }
        }
    }
    var lastError: String? = nil
    var trackingStartedAt: Date? = nil   // for "Since Xm ago" display

    // MARK: - Baseline (set by calibrate())

    private var baselineYaw: Double = 0
    private var baselinePitch: Double = 0
    private var framesToSkip: Int = 0

    // MARK: - Hysteresis state

    private var wasTriggered: Bool = false

    /// Clear thresholds are 0.1 rad below the trigger thresholds.
    /// Both axes must fall below these before the blur is dismissed.
    private var clearYawThreshold: Double { max(0.05, yawThreshold - 0.1) }
    private var clearPitchThreshold: Double { max(0.05, pitchThreshold - 0.1) }

    // MARK: - CoreMotion

    // nonisolated lets the manager be safely referenced from background closures
    nonisolated private let manager = CMHeadphoneMotionManager()
    nonisolated private let motionQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.privacyscreen.motion"
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInteractive
        return q
    }()

    // MARK: - Reconnect polling

    private var reconnectTimer: Timer?

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate = self
        checkAvailability()
    }

    // MARK: - Public API

    func checkAvailability() {
        isAvailable = manager.isDeviceMotionAvailable
    }

    func startTracking() {
        intentToTrack = true
        framesToSkip = 30
        checkAvailability()

        guard isAvailable else {
            print("[PrivacyScreen] CMHeadphoneMotionManager unavailable — AirPods not connected or head tracking disabled.")
            isActive = false
            startReconnectPolling()
            return
        }

        stopReconnectPolling()

        manager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard let self else { return }

            // Error path — stop tracking and begin polling for reconnect
            if let error {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isActive = false
                    self.isTriggered = false
                    self.wasTriggered = false
                    self.lastError = error.localizedDescription
                    print("[PrivacyScreen] Motion error: \(error.localizedDescription)")
                    self.startReconnectPolling()
                }
                return
            }

            guard let motion else { return }

            // Capture values before hopping to main actor
            let yaw   = motion.attitude.yaw
            let pitch = motion.attitude.pitch

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.rawYaw   = yaw
                self.rawPitch = pitch
                
                if self.framesToSkip > 0 {
                    self.framesToSkip -= 1
                    self.deltaYaw = 0
                    self.deltaPitch = 0
                    if self.framesToSkip == 0 {
                        self.calibrate()
                    }
                    return
                }
                
                // Helper to wrap angles to [-pi, pi]
                func normalizeAngle(_ angle: Double) -> Double {
                    var a = angle
                    while a > .pi { a -= 2 * .pi }
                    while a < -.pi { a += 2 * .pi }
                    return a
                }
                
                self.deltaYaw   = normalizeAngle(yaw   - self.baselineYaw)
                self.deltaPitch = normalizeAngle(pitch - self.baselinePitch)
                self.updateTriggerState()

                // Console readout for Block 2 testing — removed in Block 7 polish
                print(String(format: "[Motion] Δyaw: %+.3f rad  Δpitch: %+.3f rad  triggered: %@",
                             self.deltaYaw, self.deltaPitch,
                             self.isTriggered ? "YES 🔴" : "NO  🟢"))
            }
        }

        isActive = true
        lastError = nil
        trackingStartedAt = Date()
        print("[PrivacyScreen] Tracking started. Move your head to verify.")
    }

    func stopTracking() {
        intentToTrack = false
        manager.stopDeviceMotionUpdates()
        isActive         = false
        isTriggered      = false
        wasTriggered     = false
        trackingStartedAt = nil
        stopReconnectPolling()
        print("[PrivacyScreen] Tracking stopped.")
    }

    /// Snapshot current raw values as the zero baseline.
    func calibrate() {
        baselineYaw   = rawYaw
        baselinePitch = rawPitch
        deltaYaw      = 0
        deltaPitch    = 0
        isTriggered   = false
        wasTriggered  = false
        print(String(format: "[PrivacyScreen] Calibrated → baseline yaw: %.3f, pitch: %.3f",
                     baselineYaw, baselinePitch))
    }

    // MARK: - Hysteresis logic

    private func updateTriggerState() {
        let absYaw   = abs(deltaYaw)
        let absPitch = abs(deltaPitch)

        if !wasTriggered {
            if absYaw > yawThreshold || absPitch > pitchThreshold {
                wasTriggered = true
                isTriggered  = true
                
                if isParanoiaModeEnabled {
                    stopTracking()
                    lockMacScreen()
                }
            }
        } else {
            // Clear: BOTH axes must return below their clear thresholds
            if absYaw < clearYawThreshold && absPitch < clearPitchThreshold {
                wasTriggered = false
                isTriggered  = false
            }
        }
    }

    private func lockMacScreen() {
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        guard let libHandle = libHandle else { return }
        
        if let sym = dlsym(libHandle, "SACLockScreenImmediate") {
            typealias LockScreenFunc = @convention(c) () -> Void
            let lockScreen = unsafeBitCast(sym, to: LockScreenFunc.self)
            lockScreen()
        }
        dlclose(libHandle)
    }

    // MARK: - AirPods reconnect polling

    private func startReconnectPolling() {
        guard reconnectTimer == nil else { return }
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.intentToTrack, !self.isActive, self.manager.isDeviceMotionAvailable else { return }
                print("[PrivacyScreen] AirPods detected — restarting tracking.")
                self.isAvailable = true
                self.startTracking()
            }
        }
    }

    private func stopReconnectPolling() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            print("[PrivacyScreen] AirPods delegate: Connected.")
            self.isAvailable = true
            // If we have an active intent to track but were paused due to disconnect, restart
            if self.intentToTrack && self.isActive == false {
                self.startTracking()
            }
        }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            print("[PrivacyScreen] AirPods delegate: Disconnected.")
            self.isAvailable = false
            self.isActive = false
            self.isTriggered = false
            self.lastError = "Disconnected"
            self.startReconnectPolling()
        }
    }
}
