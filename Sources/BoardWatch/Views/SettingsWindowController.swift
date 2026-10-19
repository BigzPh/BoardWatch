import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController {
    public static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    public func showSettings(appState: AppState) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = MinimalSettingsView(appState: appState)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "BoardWatch Settings"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.setContentSize(NSSize(width: 380, height: 420))

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func closeSettings() {
        window?.close()
    }
}
