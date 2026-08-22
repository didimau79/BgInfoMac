import AppKit
import SwiftUI

final class OverlayWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class DesktopOverlayController {
    private var windows: [OverlayWindow] = []
    private var hostingViews: [NSHostingView<OverlayContentView>] = []
    private let prefs = Preferences.shared

    func reloadWindows(with snapshot: SystemSnapshot) {
        removeAllWindows()

        guard prefs.overlayVisible else { return }

        for screen in targetScreens() {
            let (window, hosting) = makeWindow(for: screen, snapshot: snapshot)
            windows.append(window)
            hostingViews.append(hosting)
            window.orderFront(nil)
        }
    }

    func updateContent(with snapshot: SystemSnapshot) {
        guard prefs.overlayVisible else {
            if !windows.isEmpty { removeAllWindows() }
            return
        }
        let screens = targetScreens()
        if windows.count != screens.count {
            reloadWindows(with: snapshot)
            return
        }
        for (index, screen) in screens.enumerated() {
            let window = windows[index]
            let hosting = hostingViews[index]
            // Actualiza la vista existente en vez de crear una nueva: evita el
            // "fantasma" que aparecía al mover/recrear la ventana en cada cambio.
            hosting.rootView = OverlayContentView(snapshot: snapshot, prefs: prefs)
            reposition(window: window, hosting: hosting, on: screen)
        }
    }

    private func makeWindow(for screen: NSScreen, snapshot: SystemSnapshot) -> (OverlayWindow, NSHostingView<OverlayContentView>) {
        let hosting = NSHostingView(rootView: OverlayContentView(snapshot: snapshot, prefs: prefs))
        let initialSize = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: initialSize)

        let window = OverlayWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isMovable = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting

        reposition(window: window, hosting: hosting, on: screen)

        return (window, hosting)
    }

    /// Mide el tamaño real del contenido actual y mueve/redimensiona la
    /// ventana en un solo paso (mismo `setFrame`), sin recrear ni reasignar
    /// la vista — así no queda un frame intermedio mal dibujado.
    private func reposition(window: NSWindow, hosting: NSView, on screen: NSScreen) {
        let contentSize = hosting.fittingSize
        let marginX = CGFloat(prefs.marginX)
        let marginY = CGFloat(prefs.marginY)
        // Horizontal: se mide desde el área segura (evita, por ej., el Dock
        // si está a un costado). Vertical: se mide directamente desde el
        // borde físico de la pantalla, así 0 siempre es "pegado al borde" —
        // subir el valor lo aleja del borde (y de a poco, del Dock si está
        // abajo), sin necesitar márgenes negativos.
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        var origin = NSPoint.zero

        switch prefs.corner {
        case .topLeft:
            origin = NSPoint(x: visibleFrame.minX + marginX, y: fullFrame.maxY - contentSize.height - marginY)
        case .topRight:
            origin = NSPoint(x: visibleFrame.maxX - contentSize.width - marginX, y: fullFrame.maxY - contentSize.height - marginY)
        case .bottomLeft:
            origin = NSPoint(x: visibleFrame.minX + marginX, y: fullFrame.minY + marginY)
        case .bottomRight:
            origin = NSPoint(x: visibleFrame.maxX - contentSize.width - marginX, y: fullFrame.minY + marginY)
        }

        // Por seguridad, nunca dejar que quede fuera de los bordes físicos de
        // ESTA pantalla (relevante sobre todo en multi-monitor, donde solo
        // una pantalla reserva espacio para el Dock).
        origin.x = min(max(origin.x, fullFrame.minX), fullFrame.maxX - contentSize.width)
        origin.y = min(max(origin.y, fullFrame.minY), fullFrame.maxY - contentSize.height)

        let newFrame = NSRect(origin: origin, size: contentSize)
        guard window.frame != newFrame else { return }
        window.setFrame(newFrame, display: true)
    }

    private func targetScreens() -> [NSScreen] {
        let target = prefs.displayTarget
        guard target != Preferences.allDisplaysTarget else { return NSScreen.screens }
        if let match = NSScreen.screens.first(where: { $0.localizedName == target }) {
            return [match]
        }
        return NSScreen.screens
    }

    private func removeAllWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        hostingViews.removeAll()
    }
}
