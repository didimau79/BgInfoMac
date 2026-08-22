import AppKit
import SwiftUI

final class MenuPopoverController {
    private let popover = NSPopover()
    private let prefs = Preferences.shared
    private var latestSnapshot = SystemSnapshot()
    // Se reusa el mismo NSHostingController siempre, actualizando su rootView
    // in place en cada refresh. Antes se creaba uno nuevo y se reemplazaba
    // contentViewController cada vez, lo que producía un parpadeo visible al
    // reconstruir toda la jerarquía de vistas — el mismo problema que ya se
    // había resuelto para el overlay de escritorio ("ghosting").
    private let hosting: NSHostingController<MenuPopoverView>
    // Se decide una sola vez por apertura (no en cada refresh periódico
    // mientras está abierta), para que no aparezca/desaparezca sola.
    private var showDonationPromptThisOpen = false

    init() {
        popover.behavior = .transient
        hosting = NSHostingController(rootView: MenuPopoverView(snapshot: latestSnapshot, prefs: prefs, showDonationPrompt: false))
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
    }

    var isShown: Bool { popover.isShown }

    func updateSnapshot(_ snapshot: SystemSnapshot) {
        latestSnapshot = snapshot
        if popover.isShown {
            refreshContent()
        }
    }

    func toggle(relativeTo view: NSView) {
        if popover.isShown {
            popover.close()
        } else {
            // Sin activar la app, la ventana del popover no queda como "key":
            // el hover (tooltips) no responde hasta un segundo click, y el
            // cierre automático al clickear afuera se vuelve poco confiable.
            NSApp.activate(ignoringOtherApps: true)
            showDonationPromptThisOpen = prefs.registerPopoverOpenAndCheckDonationPrompt()
            refreshContent()
            popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
    }

    private func refreshContent() {
        hosting.rootView = MenuPopoverView(snapshot: latestSnapshot, prefs: prefs, showDonationPrompt: showDonationPromptThisOpen)
    }
}
