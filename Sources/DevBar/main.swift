import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 330, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ServerListView())

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "DevBar")
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

withExtendedLifetime(delegate) {
    app.run()
}
