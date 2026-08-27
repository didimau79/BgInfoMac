import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let contextMenu = NSMenu()
    private let popoverController = MenuPopoverController()
    private let prefs = Preferences.shared
    private var preferencesWindowController: PreferencesWindowController?
    private var aboutWindowController: AboutWindowController?
    private var helpWindowController: HelpWindowController?
    var onRefreshNow: (() -> Void)?
    var onPopoverWillShow: (() -> Void)?

    private var lang: AppLanguage { prefs.appLanguage }

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        contextMenu.delegate = self

        if let button = statusItem.button {
            button.image = StatusBarController.loadStatusIcon()
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        rebuildMenu()
    }

    func updateSnapshot(_ snapshot: SystemSnapshot) {
        popoverController.updateSnapshot(snapshot)
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
        } else {
            guard let button = statusItem.button else { return }
            // Al abrir la burbuja, refrescamos justo antes para que muestre
            // datos frescos (ej. espacio en disco) en vez de lo que dejó el
            // último tick del timer periódico.
            if !popoverController.isShown {
                onPopoverWillShow?()
            }
            popoverController.toggle(relativeTo: button)
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    func rebuildMenu() {
        contextMenu.removeAllItems()

        contextMenu.addItem(NSMenuItem(title: L(.aboutMenuItem, lang), action: #selector(openAbout), keyEquivalent: ""))
        contextMenu.addItem(.separator())

        contextMenu.addItem(toggleItem(L(.showOverlay, lang), isOn: prefs.overlayVisible, action: #selector(toggleOverlay)))
        contextMenu.addItem(toggleItem(L(.launchAtLogin, lang), isOn: prefs.launchAtLogin, action: #selector(toggleLaunchAtLogin)))
        contextMenu.addItem(.separator())

        let intervalItem = NSMenuItem(title: L(.refreshEvery, lang), action: nil, keyEquivalent: "")
        let intervalMenu = NSMenu()
        for interval in RefreshInterval.allCases {
            let item = toggleItem(interval.label(lang), isOn: prefs.refreshInterval == interval, action: #selector(setInterval(_:)))
            item.representedObject = interval
            intervalMenu.addItem(item)
        }
        intervalItem.submenu = intervalMenu
        contextMenu.addItem(intervalItem)

        contextMenu.addItem(.separator())
        contextMenu.addItem(NSMenuItem(title: L(.refreshNow, lang), action: #selector(refreshNow), keyEquivalent: "r"))
        contextMenu.addItem(NSMenuItem(title: L(.preferencesMenuItem, lang), action: #selector(openPreferences), keyEquivalent: ","))
        contextMenu.addItem(NSMenuItem(title: L(.helpMenuItem, lang), action: #selector(openHelp), keyEquivalent: "?"))
        contextMenu.addItem(.separator())
        contextMenu.addItem(NSMenuItem(title: L(.quitMenuItem, lang), action: #selector(quit), keyEquivalent: "q"))

        for item in contextMenu.items {
            item.target = self
            item.submenu?.items.forEach { $0.target = self }
        }
    }

    /// Primero intenta el catálogo de assets (proyecto de Xcode). Si no está
    /// ahí, busca el PNG suelto que copia build_app.sh (paquete SPM) — Xcode
    /// fusiona los sueltos @1x/@2x en un único .tiff con otro nombre, por
    /// eso ese primer intento falla ahí y hace falta el catálogo.
    private static func loadStatusIcon() -> NSImage? {
        let image = NSImage(named: "StatusIcon")
            ?? Bundle.main.url(forResource: "StatusIcon@2x", withExtension: "png").flatMap(NSImage.init(contentsOf:))
            ?? NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: "BGInfoMac")
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true
        return image
    }

    private func toggleItem(_ title: String, isOn: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.state = isOn ? .on : .off
        return item
    }

    @objc private func toggleOverlay() {
        prefs.overlayVisible.toggle()
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        prefs.launchAtLogin.toggle()
        rebuildMenu()
    }

    @objc private func setInterval(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? RefreshInterval else { return }
        prefs.refreshInterval = interval
        rebuildMenu()
    }

    @objc private func refreshNow() {
        onRefreshNow?()
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.show()
    }

    @objc private func openAbout() {
        let controller = AboutWindowController()
        aboutWindowController = controller
        controller.show()
    }

    @objc private func openHelp() {
        let controller = HelpWindowController()
        helpWindowController = controller
        controller.show()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
