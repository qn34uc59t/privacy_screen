import SwiftUI
import AppKit

@main
struct PrivacyScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — this is a menu bar only app.
        // All UI is managed by AppDelegate via NSStatusItem + NSPopover.
        Settings { EmptyView() }
    }
}
