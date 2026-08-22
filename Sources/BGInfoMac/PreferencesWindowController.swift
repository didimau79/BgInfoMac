import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    private static let tabHeaderAllowance: CGFloat = 54
    private static let minContentHeight: CGFloat = 320
    private static let maxContentHeight: CGFloat = 760

    convenience init() {
        let vm = PreferencesViewModel()
        var capturedWindow: NSWindow?

        let rootView = PreferencesView(vm: vm, onContentSizeChange: { size in
            DispatchQueue.main.async {
                guard let window = capturedWindow else { return }
                PreferencesWindowController.resize(window, toMeasuredContentHeight: size.height)
            }
        })

        let hosting = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .resizable]
        window.contentMinSize = NSSize(width: 460, height: PreferencesWindowController.minContentHeight)
        window.setContentSize(NSSize(width: 480, height: 560))
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        capturedWindow = window

        self.init(window: window)
        window.title = L(.prefsWindowTitle, vm.language)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Ajusta solo la altura de la ventana al contenido real del tab activo
    /// (deja el ancho como esté, para no pelear con un resize manual del usuario).
    private static func resize(_ window: NSWindow, toMeasuredContentHeight measuredHeight: CGFloat) {
        let height = max(minContentHeight, min(measuredHeight + tabHeaderAllowance, maxContentHeight))
        let currentContentSize = window.contentView?.frame.size ?? NSSize(width: 480, height: 560)
        let newContentSize = NSSize(width: currentContentSize.width, height: height)

        let currentFrame = window.frame
        let newFrameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: newContentSize)).size
        guard abs(newFrameSize.height - currentFrame.height) > 1 else { return }

        var newFrame = currentFrame
        let deltaHeight = newFrameSize.height - currentFrame.height
        newFrame.origin.y -= deltaHeight
        newFrame.size = newFrameSize
        window.setFrame(newFrame, display: true, animate: true)
    }
}
