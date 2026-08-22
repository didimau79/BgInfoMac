import Foundation
import AppKit
import ServiceManagement

enum ScreenCorner: String, CaseIterable, Codable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    func label(_ lang: AppLanguage) -> String {
        switch self {
        case .topLeft: return L(.cornerTopLeft, lang)
        case .topRight: return L(.cornerTopRight, lang)
        case .bottomLeft: return L(.cornerBottomLeft, lang)
        case .bottomRight: return L(.cornerBottomRight, lang)
        }
    }
}

enum RefreshInterval: TimeInterval, CaseIterable {
    case never = 0
    case fiveSeconds = 5
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300

    func label(_ lang: AppLanguage) -> String {
        switch self {
        case .never: return L(.intervalNever, lang)
        case .fiveSeconds: return L(.interval5s, lang)
        case .thirtySeconds: return L(.interval30s, lang)
        case .oneMinute: return L(.interval1m, lang)
        case .fiveMinutes: return L(.interval5m, lang)
        }
    }
}

enum AppearanceMode: String, CaseIterable, Codable {
    case system
    case light
    case dark

    func label(_ lang: AppLanguage) -> String {
        switch self {
        case .system: return L(.appearanceSystem, lang)
        case .light: return L(.appearanceLight, lang)
        case .dark: return L(.appearanceDark, lang)
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let overlayVisible = "overlayVisible"
        static let corner = "overlayCorner"
        static let marginX = "overlayMarginX"
        static let marginY = "overlayMarginY"
        static let refreshInterval = "refreshInterval"
        static let fontSize = "fontSize"

        static let textColorHex = "textColorHex"
        static let backgroundColorHex = "backgroundColorHex"
        static let backgroundOpacity = "backgroundOpacity"

        static let layoutConfig = "layoutConfigV2"
        static let customMessageText = "customMessageText"

        static let menuLayoutConfig = "menuLayoutConfigV1"
        static let menuCustomMessageText = "menuCustomMessageText"

        static let appLanguage = "appLanguage"
        static let appearanceMode = "appearanceMode"

        static let displayTarget = "displayTarget"

        static let donationPromptDisabled = "donationPromptDisabled"
        static let popoverOpenCount = "popoverOpenCount"
    }

    static let allDisplaysTarget = "__all__"

    private init() {
        defaults.register(defaults: [
            Keys.overlayVisible: true,
            Keys.corner: ScreenCorner.topRight.rawValue,
            Keys.marginX: 24.0,
            Keys.marginY: 24.0,
            Keys.refreshInterval: RefreshInterval.fiveSeconds.rawValue,
            Keys.fontSize: 12.0,

            Keys.textColorHex: "FFFFFF",
            Keys.backgroundColorHex: "000000",
            Keys.backgroundOpacity: 0.0,

            Keys.customMessageText: "",
            Keys.menuCustomMessageText: "",

            Keys.appLanguage: AppLanguage.system.rawValue,
            Keys.appearanceMode: AppearanceMode.system.rawValue,

            Keys.displayTarget: Preferences.allDisplaysTarget
        ])
    }

    var overlayVisible: Bool {
        get { defaults.bool(forKey: Keys.overlayVisible) }
        set { defaults.set(newValue, forKey: Keys.overlayVisible); notifyChange() }
    }

    var corner: ScreenCorner {
        get { ScreenCorner(rawValue: defaults.string(forKey: Keys.corner) ?? "") ?? .topRight }
        set { defaults.set(newValue.rawValue, forKey: Keys.corner); notifyChange() }
    }

    var marginX: Double {
        get { defaults.double(forKey: Keys.marginX) }
        set { defaults.set(newValue, forKey: Keys.marginX); notifyChange() }
    }

    var marginY: Double {
        get { defaults.double(forKey: Keys.marginY) }
        set { defaults.set(newValue, forKey: Keys.marginY); notifyChange() }
    }

    var refreshInterval: RefreshInterval {
        get { RefreshInterval(rawValue: defaults.double(forKey: Keys.refreshInterval)) ?? .fiveSeconds }
        set { defaults.set(newValue.rawValue, forKey: Keys.refreshInterval); notifyChange() }
    }

    var fontSize: Double {
        get { defaults.double(forKey: Keys.fontSize) }
        set { defaults.set(newValue, forKey: Keys.fontSize); notifyChange() }
    }

    var textColorHex: String {
        get { defaults.string(forKey: Keys.textColorHex) ?? "FFFFFF" }
        set { defaults.set(newValue, forKey: Keys.textColorHex); notifyChange() }
    }

    var backgroundColorHex: String {
        get { defaults.string(forKey: Keys.backgroundColorHex) ?? "000000" }
        set { defaults.set(newValue, forKey: Keys.backgroundColorHex); notifyChange() }
    }

    var backgroundOpacity: Double {
        get { defaults.double(forKey: Keys.backgroundOpacity) }
        set { defaults.set(newValue, forKey: Keys.backgroundOpacity); notifyChange() }
    }

    var customMessageText: String {
        get { defaults.string(forKey: Keys.customMessageText) ?? "" }
        set { defaults.set(newValue, forKey: Keys.customMessageText); notifyChange() }
    }

    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: Keys.appLanguage) ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Keys.appLanguage); notifyChange() }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Keys.appearanceMode); notifyChange() }
    }

    /// Identificador de pantalla ("__all__" o el `localizedName` de una pantalla específica).
    var displayTarget: String {
        get { defaults.string(forKey: Keys.displayTarget) ?? Preferences.allDisplaysTarget }
        set { defaults.set(newValue, forKey: Keys.displayTarget); notifyChange() }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            guard newValue != launchAtLogin else { return }
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("BGInfoMac: no se pudo actualizar 'Iniciar al inicio de sesión': \(error)")
            }
            notifyChange()
        }
    }

    var layout: LayoutConfig {
        get {
            guard let data = defaults.data(forKey: Keys.layoutConfig),
                  var decoded = try? JSONDecoder().decode(LayoutConfig.self, from: data) else {
                return LayoutConfig.default
            }
            decoded.reconcileWithDefaults()
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.layoutConfig)
            }
            notifyChange()
        }
    }

    var menuCustomMessageText: String {
        get { defaults.string(forKey: Keys.menuCustomMessageText) ?? "" }
        set { defaults.set(newValue, forKey: Keys.menuCustomMessageText); notifyChange() }
    }

    var menuLayout: LayoutConfig {
        get {
            guard let data = defaults.data(forKey: Keys.menuLayoutConfig),
                  var decoded = try? JSONDecoder().decode(LayoutConfig.self, from: data) else {
                return LayoutConfig.default
            }
            decoded.reconcileWithDefaults()
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.menuLayoutConfig)
            }
            notifyChange()
        }
    }

    var donationPromptDisabled: Bool {
        get { defaults.bool(forKey: Keys.donationPromptDisabled) }
        set { defaults.set(newValue, forKey: Keys.donationPromptDisabled); notifyChange() }
    }

    private var popoverOpenCount: Int {
        get { defaults.integer(forKey: Keys.popoverOpenCount) }
        set { defaults.set(newValue, forKey: Keys.popoverOpenCount) }
    }

    /// Se pide una única vez, justo en la 5ª apertura de la burbuja — nunca
    /// antes, nunca después, y nunca si el usuario ya lo desactivó
    /// (permanentemente, con ⌘⇧D en la burbuja).
    func registerPopoverOpenAndCheckDonationPrompt() -> Bool {
        popoverOpenCount += 1
        guard !donationPromptDisabled, popoverOpenCount == 5 else { return false }
        // Una vez mostrado, no debe volver a aparecer — reusamos el mismo
        // flag de "desactivado" que usa el botón ✕/⌘⇧D.
        donationPromptDisabled = true
        return true
    }

    static let didChangeNotification = Notification.Name("PreferencesDidChange")

    private func notifyChange() {
        NotificationCenter.default.post(name: Preferences.didChangeNotification, object: nil)
    }
}
