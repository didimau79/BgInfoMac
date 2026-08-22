import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let infoProvider = SystemInfoProvider()
    private let overlayController = DesktopOverlayController()
    private var statusBarController: StatusBarController!
    private let prefs = Preferences.shared

    private var refreshTimer: Timer?
    private var latestSnapshot = SystemSnapshot()

    private var startupNetworkRetries = 0
    private let maxStartupNetworkRetries = 8
    private let startupNetworkRetryDelay: TimeInterval = 3

    private let networkChangeMonitor = NetworkChangeMonitor()
    private var networkChangeDebounce: DispatchWorkItem?
    private var volumeChangeDebounce: DispatchWorkItem?

    // Evita re-consultar el país en cada refresh: solo se pide de nuevo si
    // la IP pública realmente cambió.
    private var countryLookupIP: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.appearance = prefs.appearanceMode.nsAppearance

        // Baja el delay por defecto (~1.5s) con el que AppKit muestra los
        // tooltips, para que las barras de RAM/almacenamiento respondan casi
        // al instante al pasar el mouse.
        UserDefaults.standard.register(defaults: ["NSInitialToolTipDelay": 150])

        statusBarController = StatusBarController()
        statusBarController.onRefreshNow = { [weak self] in self?.refresh() }
        statusBarController.onPopoverWillShow = { [weak self] in self?.refresh() }

        NotificationCenter.default.addObserver(self, selector: #selector(preferencesChanged),
                                                name: Preferences.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
                                                name: NSApplication.didChangeScreenParametersNotification, object: nil)

        WifiAuthorization.shared.onAuthorizationChange = { [weak self] in self?.refresh() }
        WifiAuthorization.shared.requestIfNeeded()

        networkChangeMonitor.onChange = { [weak self] in self?.handleNetworkChange() }
        networkChangeMonitor.start()

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(self, selector: #selector(handleVolumeChange),
                                     name: NSWorkspace.didMountNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(handleVolumeChange),
                                     name: NSWorkspace.didUnmountNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(handleVolumeChange),
                                     name: NSWorkspace.didRenameVolumeNotification, object: nil)

        refresh()
        scheduleTimer()
        scheduleStartupNetworkRetryIfNeeded()
    }

    /// Los cambios de red (ej. pasar de Wi-Fi a cable) suelen disparar varios
    /// avisos seguidos mientras las interfaces se estabilizan; se agrupan para
    /// terminar refrescando una sola vez.
    private func handleNetworkChange() {
        networkChangeDebounce?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.refresh() }
        networkChangeDebounce = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: workItem)
    }

    /// Conectar/desconectar un disco (externo o de red) dispara didMount/didUnmount;
    /// se agrupan con el mismo criterio que los cambios de red.
    @objc private func handleVolumeChange() {
        volumeChangeDebounce?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.refresh() }
        volumeChangeDebounce = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: workItem)
    }

    /// En un arranque/reinicio recién hecho, las interfaces de red (Wi-Fi/Ethernet)
    /// pueden tardar unos segundos en tener IP asignada. Reintentamos aparte del
    /// timer normal (incluso si el usuario eligió "Nunca" como intervalo) hasta
    /// que aparezcan datos o se agoten los intentos.
    private func scheduleStartupNetworkRetryIfNeeded() {
        guard latestSnapshot.interfaces.isEmpty, startupNetworkRetries < maxStartupNetworkRetries else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + startupNetworkRetryDelay) { [weak self] in
            guard let self = self else { return }
            self.startupNetworkRetries += 1
            self.refresh()
            self.scheduleStartupNetworkRetryIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        networkChangeMonitor.stop()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func preferencesChanged() {
        scheduleTimer()
        NSApp.appearance = prefs.appearanceMode.nsAppearance
        statusBarController.rebuildMenu()
        overlayController.updateContent(with: latestSnapshot)
    }

    @objc private func screensChanged() {
        overlayController.reloadWindows(with: latestSnapshot)
    }

    private func scheduleTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        guard prefs.refreshInterval != .never else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: prefs.refreshInterval.rawValue, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func refresh() {
        var snapshot = SystemSnapshot()

        let basics = infoProvider.captureBasics()
        snapshot.hostName = basics.hostName
        snapshot.userName = basics.userName
        snapshot.osVersion = basics.osVersion
        snapshot.dateString = basics.dateString
        snapshot.serialNumber = basics.serialNumber
        snapshot.osBuild = basics.osBuild

        let hardware = infoProvider.captureHardware()
        snapshot.macModel = hardware.model
        snapshot.chipName = hardware.chip
        snapshot.uptimeString = hardware.uptime
        snapshot.totalRAMBytes = hardware.totalRAM
        snapshot.usedRAMBytes = hardware.usedRAM
        snapshot.batteryPercentage = hardware.batteryPercentage
        snapshot.batteryIsCharging = hardware.batteryIsCharging
        snapshot.batteryHealthPercent = hardware.batteryHealthPercent
        snapshot.batteryCycleCount = hardware.batteryCycleCount
        snapshot.cpuPerformanceCores = hardware.cpuPerformanceCores
        snapshot.cpuEfficiencyCores = hardware.cpuEfficiencyCores
        snapshot.cpuTotalCores = hardware.cpuTotalCores
        snapshot.gpuName = hardware.gpuName
        snapshot.gpuCoreCount = hardware.gpuCoreCount

        snapshot.volumes = infoProvider.captureVolumes()

        let network = infoProvider.captureNetwork()
        var interfaces = network.interfaces
        snapshot.wifiSSID = network.ssid
        snapshot.gatewayIP = infoProvider.captureGatewayIP()
        snapshot.dnsServers = infoProvider.captureDNSServers()
        snapshot.vpnProvider = infoProvider.captureVPNProvider()

        // Cuando hay VPN conectada, la interfaz del túnel se muestra aparte
        // (junto al resto de datos de la VPN) en vez de en la lista general.
        if snapshot.vpnProvider != nil,
           let tunnelName = infoProvider.capturePrimaryInterfaceName(),
           let tunnelIndex = interfaces.firstIndex(where: { $0.name == tunnelName }) {
            snapshot.vpnTunnelIP = interfaces.remove(at: tunnelIndex).address
        } else {
            snapshot.vpnTunnelIP = nil
        }
        snapshot.interfaces = interfaces
        snapshot.publicIP = latestSnapshot.publicIP
        snapshot.publicIPCountryName = latestSnapshot.publicIPCountryName
        snapshot.publicIPCountryCode = latestSnapshot.publicIPCountryCode
        snapshot.ispProvider = latestSnapshot.ispProvider

        latestSnapshot = snapshot
        overlayController.updateContent(with: latestSnapshot)
        statusBarController.updateSnapshot(latestSnapshot)

        if prefs.layout.isFieldVisible(.publicIP) || prefs.menuLayout.isFieldVisible(.publicIP) {
            infoProvider.fetchPublicIP { [weak self] ip in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.latestSnapshot.publicIP = ip
                    self.overlayController.updateContent(with: self.latestSnapshot)
                    self.statusBarController.updateSnapshot(self.latestSnapshot)
                    self.lookUpCountryIfNeeded(forIP: ip)
                }
            }
        }
    }

    private func lookUpCountryIfNeeded(forIP ip: String?) {
        guard let ip = ip, ip != countryLookupIP else { return }
        infoProvider.fetchCountryInfo(forIP: ip) { [weak self] name, code, isp in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.countryLookupIP = ip
                self.latestSnapshot.publicIPCountryName = name
                self.latestSnapshot.publicIPCountryCode = code
                self.latestSnapshot.ispProvider = isp
                self.overlayController.updateContent(with: self.latestSnapshot)
                self.statusBarController.updateSnapshot(self.latestSnapshot)
            }
        }
    }
}
