import AppKit
import SwiftUI

final class HelpWindowController: NSWindowController {
    convenience init() {
        let hosting = NSHostingController(rootView: HelpView())
        let window = NSWindow(contentViewController: hosting)
        window.title = L(.helpWindowTitle, Preferences.shared.appLanguage)
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 700, height: 480))
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        self.init(window: window)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
