import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "Personal Music Radio")
        statusItem.button?.title = " Workday Focus"

        let menu = NSMenu()
        menu.addItem(disabledItem("Personal Music Radio"))
        menu.addItem(disabledItem("Speaking... If · Bread"))
        menu.addItem(.separator())
        menu.addItem(actionItem("Pause", action: #selector(pause)))
        menu.addItem(actionItem("Next", action: #selector(nextTrack)))
        menu.addItem(.separator())
        menu.addItem(actionItem("Open Main Window", action: #selector(openMainWindow)))
        menu.addItem(.separator())
        menu.addItem(actionItem("Quit", action: #selector(quit)))
        statusItem.menu = menu
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func actionItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func pause() {
        // Playback wiring arrives with the AVFoundation layer.
    }

    @objc private func nextTrack() {
        // Recommendation wiring arrives with the recommendation layer.
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
