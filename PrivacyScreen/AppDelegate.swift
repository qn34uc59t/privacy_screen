import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    // Shared state
    let motionState = MotionState()
    private var blurManager: BlurOverlayManager?
    private var calibrationPanel: NSWindow?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show in Dock and Cmd+Tab switcher
        NSApp.setActivationPolicy(.regular)

        setupStatusItem()
        setupPopover()
        
        blurManager = BlurOverlayManager(motionState: motionState)
        
        // Open the calibration panel automatically on launch
        showCalibrationPanel()
    }

    func applicationWillTerminate(_ notification: Notification) {
        motionState.stopTracking()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Privacy Screen")
        button.image?.isTemplate = true          // adapts to light/dark menu bar
        button.action = #selector(togglePopover)
        button.target = self
    }

    // MARK: - Popover

    private func setupPopover() {
        let popover = NSPopover()
        popover.behavior = .transient                 // closes when user clicks outside
        popover.animates = true
        let hc = NSHostingController(
            rootView: MenuBarPopoverView(
                motionState: motionState,
                onCalibrate: { [weak self] in
                    self?.showCalibrationPanel()
                }
            )
        )
        hc.sizingOptions = .preferredContentSize
        popover.contentViewController = hc
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            motionState.refreshLaunchAtLoginStatus()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Calibration Panel (stub — wired in Block 5)

    func showCalibrationPanel() {
        if let panel = calibrationPanel {
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 680), // Increased height slightly
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .normal
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        
        panel.center()
        
        let hostingView = NSHostingView(rootView: CalibrationPanelView(motionState: motionState))
        panel.contentView = hostingView
        
        self.calibrationPanel = panel
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}
