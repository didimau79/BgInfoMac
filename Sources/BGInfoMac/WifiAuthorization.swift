import AppKit
import CoreLocation
import Combine

/// macOS solo entrega el SSID real de Wi-Fi (CWInterface.ssid()) a procesos
/// autorizados para Localización — no hay forma de evitarlo sin un entitlement
/// especial de Apple. Este helper pide el permiso una sola vez y avisa cuando
/// cambia, para poder refrescar los datos de red apenas el usuario lo concede.
final class WifiAuthorization: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = WifiAuthorization()

    private let manager = CLLocationManager()
    var onAuthorizationChange: (() -> Void)?

    @Published private(set) var isAuthorized: Bool

    private override init() {
        isAuthorized = false
        super.init()
        isAuthorized = manager.authorizationStatus == .authorizedAlways
        manager.delegate = self
    }

    func requestIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        isAuthorized = manager.authorizationStatus == .authorizedAlways
        onAuthorizationChange?()
    }
}
