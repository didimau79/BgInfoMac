import AppKit
import SwiftUI
import Combine

final class PreferencesViewModel: ObservableObject {
    private let prefs = Preferences.shared
    private var isSyncingFromPreferences = false
    private var preferencesChangeObserver: NSObjectProtocol?
    private var screenChangeObserver: NSObjectProtocol?

    @Published var screens: [NSScreen] = NSScreen.screens

    @Published var layout: LayoutConfig = .default { didSet { pushIfNeeded { prefs.layout = layout } } }
    @Published var customMessageText: String = "" { didSet { pushIfNeeded { prefs.customMessageText = customMessageText } } }

    @Published var menuLayout: LayoutConfig = .default { didSet { pushIfNeeded { prefs.menuLayout = menuLayout } } }
    @Published var menuCustomMessageText: String = "" { didSet { pushIfNeeded { prefs.menuCustomMessageText = menuCustomMessageText } } }

    @Published var overlayVisible: Bool = true { didSet { pushIfNeeded { prefs.overlayVisible = overlayVisible } } }

    @Published var corner: ScreenCorner = .topRight { didSet { pushIfNeeded { prefs.corner = corner } } }
    @Published var marginX: Double = 24 { didSet { pushIfNeeded { prefs.marginX = marginX } } }
    @Published var marginY: Double = 24 { didSet { pushIfNeeded { prefs.marginY = marginY } } }
    @Published var displayTarget: String = Preferences.allDisplaysTarget { didSet { pushIfNeeded { prefs.displayTarget = displayTarget } } }

    @Published var launchAtLogin: Bool = false { didSet { pushIfNeeded { prefs.launchAtLogin = launchAtLogin } } }

    @Published var textColor: Color = .white { didSet { pushIfNeeded { prefs.textColorHex = NSColor(textColor).hexString } } }
    @Published var backgroundColor: Color = .black { didSet { pushIfNeeded { prefs.backgroundColorHex = NSColor(backgroundColor).hexString } } }
    @Published var backgroundOpacity: Double = 0.0 { didSet { pushIfNeeded { prefs.backgroundOpacity = backgroundOpacity } } }
    @Published var fontSize: Double = 12.0 { didSet { pushIfNeeded { prefs.fontSize = fontSize } } }

    @Published var language: AppLanguage = .system { didSet { pushIfNeeded { prefs.appLanguage = language } } }
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            pushIfNeeded {
                prefs.appearanceMode = appearanceMode
                NSApp.appearance = appearanceMode.nsAppearance
            }
        }
    }

    init() {
        syncFromPreferences()

        preferencesChangeObserver = NotificationCenter.default.addObserver(
            forName: Preferences.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.syncFromPreferences()
        }

        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.screens = NSScreen.screens
        }
    }

    deinit {
        if let token = preferencesChangeObserver {
            NotificationCenter.default.removeObserver(token)
        }
        if let token = screenChangeObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    /// Evita el eco: si el cambio se originó acá mismo (el usuario tocó un
    /// control), no hace falta re-escribir en Preferences en medio de un sync.
    private func pushIfNeeded(_ write: () -> Void) {
        guard !isSyncingFromPreferences else { return }
        write()
    }

    /// Re-lee todo desde Preferences. Se llama al abrir la ventana y cada vez
    /// que algo cambia por otra vía (ej. el toggle del menú contextual), para
    /// que la ventana de Preferencias, si está abierta, quede sincronizada en
    /// ambos sentidos.
    private func syncFromPreferences() {
        isSyncingFromPreferences = true
        defer { isSyncingFromPreferences = false }

        if layout != prefs.layout { layout = prefs.layout }
        if customMessageText != prefs.customMessageText { customMessageText = prefs.customMessageText }

        if menuLayout != prefs.menuLayout { menuLayout = prefs.menuLayout }
        if menuCustomMessageText != prefs.menuCustomMessageText { menuCustomMessageText = prefs.menuCustomMessageText }

        if overlayVisible != prefs.overlayVisible { overlayVisible = prefs.overlayVisible }

        if corner != prefs.corner { corner = prefs.corner }
        if marginX != prefs.marginX { marginX = prefs.marginX }
        if marginY != prefs.marginY { marginY = prefs.marginY }
        if displayTarget != prefs.displayTarget { displayTarget = prefs.displayTarget }
        if launchAtLogin != prefs.launchAtLogin { launchAtLogin = prefs.launchAtLogin }

        if NSColor(textColor).hexString != prefs.textColorHex {
            textColor = Color(hex: prefs.textColorHex, fallback: .white)
        }
        if NSColor(backgroundColor).hexString != prefs.backgroundColorHex {
            backgroundColor = Color(hex: prefs.backgroundColorHex, fallback: .black)
        }
        if backgroundOpacity != prefs.backgroundOpacity { backgroundOpacity = prefs.backgroundOpacity }
        if fontSize != prefs.fontSize { fontSize = prefs.fontSize }

        if language != prefs.appLanguage { language = prefs.appLanguage }
        if appearanceMode != prefs.appearanceMode { appearanceMode = prefs.appearanceMode }
    }
}
