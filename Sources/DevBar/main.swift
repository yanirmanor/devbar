import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var monitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let hostingController = NSHostingController(
            rootView: ServerListView()
                .environment(\.colorScheme, .dark)
        )
        hostingController.sizingOptions = [.preferredContentSize]

        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentViewController = hostingController

        // Wrap content in a rounded‑corner clipping view
        if let contentView = panel.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
        }

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "chevron.left.forwardslash.chevron.right",
                accessibilityDescription: "DevBar"
            )
            button.image?.size = NSSize(width: 18, height: 14)
            button.image?.isTemplate = true
            button.action = #selector(togglePanel(_:))
            button.target = self
        }
    }

    @objc func togglePanel(_ sender: AnyObject?) {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func openPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        // Size the panel to fit its content
        panel.contentViewController?.view.layoutSubtreeIfNeeded()
        let size = panel.contentViewController?.view.fittingSize ?? NSSize(width: 340, height: 300)
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))

        let x = buttonRect.midX - size.width / 2
        let y = buttonRect.minY - size.height - 4

        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Close on outside click
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
    }

    private func closePanel() {
        panel.orderOut(nil)
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
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
