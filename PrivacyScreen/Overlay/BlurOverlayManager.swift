import AppKit
import Combine
import SwiftUI

final class BlurOverlayManager {
    private let motionState: MotionState
    private var windows: [NSScreen: BlurOverlayWindow] = [:]
    
    init(motionState: MotionState) {
        self.motionState = motionState
        
        // Build initial windows
        rebuildWindows()
        
        // Listen for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Observe trigger state without Combine by observing using withObservationTracking or a simple manual poll/callback.
        // Wait, @Observable doesn't have Combine publishers easily without withObservationTracking.
        // Actually, since we're in a class, let's just use withObservationTracking in a loop.
        startObserving()
    }
    
    @MainActor
    private func startObserving() {
        // A recursive function to observe state changes using withObservationTracking
        func observe() {
            withObservationTracking {
                _ = motionState.isTriggered
            } onChange: {
                Task { @MainActor in
                    if self.motionState.isTriggered {
                        self.show()
                    } else {
                        self.hide()
                    }
                    observe() // re-register
                }
            }
        }
        observe()
    }
    
    @MainActor
    @objc private func rebuildWindows() {
        // Clean up old windows
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
        
        // Create new window for each screen
        for screen in NSScreen.screens {
            let window = BlurOverlayWindow(screen: screen)
            windows[screen] = window
        }
        
        // If currently triggered, show them immediately
        if motionState.isTriggered {
            show()
        }
    }
    
    @MainActor
    private func show() {
        for window in windows.values {
            if !window.isVisible {
                window.alphaValue = 0.0
                window.orderFront(nil)
            }
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            for window in windows.values {
                window.animator().alphaValue = 1.0
            }
        }, completionHandler: nil)
    }
    
    @MainActor
    private func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            for window in windows.values {
                window.animator().alphaValue = 0.0
            }
        }, completionHandler: {
            // Only orderOut if we actually reached 0, avoiding disappearing if show() was called mid-animation
            for window in self.windows.values {
                if window.alphaValue == 0.0 {
                    window.orderOut(nil)
                }
            }
        })
    }
}

final class BlurOverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.screenSaverWindow.rawValue) + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.ignoresMouseEvents = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.alphaValue = 0 // start hidden
        
        let visualEffect = NSVisualEffectView(frame: screen.frame)
        visualEffect.material = .fullScreenUI
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        
        self.contentView = visualEffect
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
