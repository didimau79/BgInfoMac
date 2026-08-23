import Foundation
import Darwin
import CoreWLAN
import IOKit
import IOKit.ps
import Metal
import SystemConfiguration

enum VolumeKind {
    case internalDisk
    case external
    case network
}

struct VolumeInfo: Identifiable {
    let id = UUID()
    let name: String
    let totalBytes: Int64
    let availableBytes: Int64
    let usedBytes: Int64
    let kind: VolumeKind
    let formatDescription: String?

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

enum NetworkInterfaceKind {
    case wifi
    case ethernet
    case other
}

struct NetworkInterfaceInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let kind: NetworkInterfaceKind
}

struct SystemSnapshot {
    var hostName: String = ""
    var userName: String = ""
    var osVersion: String = ""
    var dateString: String = ""
    var serialNumber: String = ""
    var osBuild: String = ""

    var macModel: String = ""
    var chipName: String = ""
    var uptimeString: String = ""
    var totalRAMBytes: UInt64 = 0
    var usedRAMBytes: UInt64 = 0

    var batteryPercentage: Int?
    var batteryIsCharging: Bool = false
    var batteryHealthPercent: Int?
    var batteryCycleCount: Int?
    var batteryTimeRemainingMinutes: Int?

    var cpuPerformanceCores: Int?
    var cpuEfficiencyCores: Int?
    var cpuTotalCores: Int = 0

    var gpuName: String = ""
    var gpuCoreCount: Int?

    var volumes: [VolumeInfo] = []

    var interfaces: [NetworkInterfaceInfo] = []
    var wifiSSID: String?
    var publicIP: String?
    var publicIPCountryName: String?
    var publicIPCountryCode: String?
    var ispProvider: String?
    var gatewayIP: String?
    var dnsServers: [String] = []
    var vpnProvider: String?
    var vpnTunnelIP: String?
}

final class SystemInfoProvider {

    private let byteFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        // Base 1000 (decimal), igual que Finder — la referencia que la
        // mayoría de la gente usa para "espacio disponible". `df` en
        // Terminal usa base 1024 y además calcula "Used" con una lógica
        // interna de APFS que no representa el uso real del disco (ver
        // captureVolumes), así que no intentamos igualarlo.
        f.countStyle = .file
        // Sin esto, ByteCountFormatter escribe "Zero KB" en vez de "0 KB"
        // cuando el valor es 0 (ej. un disco sin espacio libre).
        f.allowsNonnumericFormatting = false
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()

    func formattedBytes(_ bytes: Int64) -> String {
        byteFormatter.string(fromByteCount: bytes)
    }

    func formattedBytes(_ bytes: UInt64) -> String {
        byteFormatter.string(fromByteCount: Int64(bitPattern: bytes))
    }

    func captureBasics() -> (hostName: String, userName: String, osVersion: String, dateString: String, serialNumber: String, osBuild: String) {
        let hostName = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        let userName = NSFullUserName().isEmpty ? NSUserName() : NSFullUserName()
        let osVersion = marketingOSVersionString()
        let dateString = dateFormatter.string(from: Date())
        let serialNumber = platformSerialNumber() ?? ""
        let osBuild = sysctlString("kern.osversion") ?? ""
        return (hostName, userName, osVersion, dateString, serialNumber, osBuild)
    }

    private func platformSerialNumber() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard platformExpert != 0 else { return nil }
        defer { IOObjectRelease(platformExpert) }
        guard let value = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        return value.takeRetainedValue() as? String
    }

    private func marketingOSVersionString() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let versionNumbers = "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        let name = macOSMarketingName(majorVersion: v.majorVersion, minorVersion: v.minorVersion)
        guard let name = name else { return "macOS \(versionNumbers)" }
        return "macOS \(name) \(versionNumbers)"
    }

    private func macOSMarketingName(majorVersion: Int, minorVersion: Int) -> String? {
        if majorVersion == 10 {
            switch minorVersion {
            case 15: return "Catalina"
            case 14: return "Mojave"
            case 13: return "High Sierra"
            case 12: return "Sierra"
            default: return nil
            }
        }
        switch majorVersion {
        case 26: return "Tahoe"
        case 15: return "Sequoia"
        case 14: return "Sonoma"
        case 13: return "Ventura"
        case 12: return "Monterey"
        case 11: return "Big Sur"
        default: return nil
        }
    }

    struct HardwareSnapshot {
        var model = ""
        var chip = ""
        var uptime = ""
        var totalRAM: UInt64 = 0
        var usedRAM: UInt64 = 0

        var batteryPercentage: Int?
        var batteryIsCharging = false
        var batteryHealthPercent: Int?
        var batteryCycleCount: Int?
        var batteryTimeRemainingMinutes: Int?

        var cpuPerformanceCores: Int?
        var cpuEfficiencyCores: Int?
        var cpuTotalCores = 0

        var gpuName = ""
        var gpuCoreCount: Int?
    }

    func captureHardware() -> HardwareSnapshot {
        var result = HardwareSnapshot()

        result.model = sysctlString("hw.model") ?? "Desconocido"
        var chip = sysctlString("machdep.cpu.brand_string") ?? ""
        if chip.isEmpty { chip = result.model }
        result.chip = chip

        result.uptime = formattedUptime(ProcessInfo.processInfo.systemUptime)

        result.totalRAM = ProcessInfo.processInfo.physicalMemory
        result.usedRAM = currentUsedMemory() ?? 0

        let battery = captureBattery()
        result.batteryPercentage = battery?.percentage
        result.batteryIsCharging = battery?.isCharging ?? false
        result.batteryHealthPercent = battery?.healthPercent
        result.batteryCycleCount = battery?.cycleCount
        result.batteryTimeRemainingMinutes = battery?.timeRemainingMinutes

        result.cpuPerformanceCores = sysctlInt32("hw.perflevel0.physicalcpu").map(Int.init)
        result.cpuEfficiencyCores = sysctlInt32("hw.perflevel1.physicalcpu").map(Int.init)
        result.cpuTotalCores = Int(sysctlInt32("hw.physicalcpu") ?? 0)

        result.gpuName = MTLCreateSystemDefaultDevice()?.name ?? result.model
        result.gpuCoreCount = gpuCoreCountFromIORegistry()

        return result
    }

    private struct BatteryInfo {
        let percentage: Int
        let isCharging: Bool
        let healthPercent: Int?
        let cycleCount: Int?
        let timeRemainingMinutes: Int?
    }

    /// Mac de escritorio sin batería → devuelve nil, y el campo simplemente
    /// no se muestra (mismo criterio que el resto de los campos opcionales).
    private func captureBattery() -> BatteryInfo? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              let current = description[kIOPSCurrentCapacityKey] as? Int,
              let max = description[kIOPSMaxCapacityKey] as? Int, max > 0 else {
            return nil
        }
        let percentage = Int((Double(current) / Double(max) * 100).rounded())
        let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false

        // macOS devuelve -1 mientras todavía está calculando la estimación
        // (recién conectado/desconectado el cargador) — en ese caso no
        // mostramos nada, en vez de un número sin sentido.
        let timeKey = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        let rawMinutes = description[timeKey] as? Int
        let timeRemainingMinutes = (rawMinutes ?? -1) >= 0 ? rawMinutes : nil

        let (cycleCount, healthPercent) = batteryRegistryInfo()
        return BatteryInfo(percentage: percentage, isCharging: isCharging, healthPercent: healthPercent, cycleCount: cycleCount, timeRemainingMinutes: timeRemainingMinutes)
    }

    /// El "salud"/ciclos no vienen en IOPowerSources; hay que leerlos del
    /// servicio IOKit de la batería inteligente.
    private func batteryRegistryInfo() -> (cycleCount: Int?, healthPercent: Int?) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return (nil, nil) }
        defer { IOObjectRelease(service) }

        func intProperty(_ key: String) -> Int? {
            guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0) else { return nil }
            return value.takeRetainedValue() as? Int
        }

        let cycleCount = intProperty("CycleCount")
        // "MaxCapacity" es un porcentaje en Apple Silicon (no mAh), así que no
        // sirve para compararlo contra "DesignCapacity" (que sí está en mAh).
        // "AppleRawMaxCapacity" es la que está en la misma escala (mAh).
        var health: Int?
        if let rawMaxCapacity = intProperty("AppleRawMaxCapacity"), let designCapacity = intProperty("DesignCapacity"), designCapacity > 0 {
            health = Int((Double(rawMaxCapacity) / Double(designCapacity) * 100).rounded())
        }
        return (cycleCount, health)
    }

    /// Solo existe en Apple Silicon (el registro "AGXAccelerator" no aparece
    /// en Macs Intel); si no está, mostramos el nombre de la GPU sin núcleos.
    private func gpuCoreCountFromIORegistry() -> Int? {
        let matching = IOServiceMatching("AGXAccelerator")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        guard let value = IORegistryEntryCreateCFProperty(service, "gpu-core-count" as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        return value.takeRetainedValue() as? Int
    }

    private func sysctlInt32(_ name: String) -> Int32? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }

    func captureVolumes() -> [VolumeInfo] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeIsInternalKey, .volumeIsLocalKey, .volumeIsBrowsableKey, .volumeLocalizedFormatDescriptionKey]
        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return []
        }
        var result: [VolumeInfo] = []
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            guard values.volumeIsBrowsable != false else { continue }
            let name = values.volumeName ?? url.lastPathComponent
            let total = Int64(values.volumeTotalCapacity ?? 0)
            // "For important usage" es la misma métrica que usa Finder para
            // "disponible" (cuenta el espacio purgable de snapshots locales
            // como recuperable). `df` en Terminal usa otra cuenta distinta
            // para "Used" (específica del volumen de Sistema en Catalina+,
            // no representa el uso real del disco), por eso no la seguimos.
            let available = values.volumeAvailableCapacityForImportantUsage
                ?? Int64(values.volumeAvailableCapacity ?? 0)
            guard total > 0 else { continue }
            let used = max(0, total - available)

            let kind: VolumeKind
            if values.volumeIsLocal == false {
                kind = .network
            } else if values.volumeIsInternal == false {
                kind = .external
            } else {
                kind = .internalDisk
            }

            result.append(VolumeInfo(name: name, totalBytes: total, availableBytes: available, usedBytes: used, kind: kind, formatDescription: values.volumeLocalizedFormatDescription))
        }
        return result.sorted { $0.totalBytes > $1.totalBytes }
    }

    func captureNetwork() -> (interfaces: [NetworkInterfaceInfo], ssid: String?) {
        var interfaces: [NetworkInterfaceInfo] = []
        let wifiInterfaceNames = Set(CWWiFiClient.shared().interfaceNames() ?? [])

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr {
            var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
            while let current = ptr {
                defer { ptr = current.pointee.ifa_next }
                let interface = current.pointee
                let flags = Int32(interface.ifa_flags)
                guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0 else { continue }

                let family = interface.ifa_addr.pointee.sa_family
                guard family == UInt8(AF_INET) else { continue }

                var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                         &hostBuffer, socklen_t(hostBuffer.count),
                                         nil, 0, NI_NUMERICHOST)
                guard result == 0 else { continue }
                let address = String(cString: hostBuffer)
                let name = String(cString: interface.ifa_name)

                let kind: NetworkInterfaceKind
                if wifiInterfaceNames.contains(name) {
                    kind = .wifi
                } else if name.hasPrefix("en") {
                    kind = .ethernet
                } else {
                    kind = .other
                }

                interfaces.append(NetworkInterfaceInfo(name: name, address: address, kind: kind))
            }
            freeifaddrs(ifaddrPtr)
        }

        let ssid = CWWiFiClient.shared().interface()?.ssid()

        return (interfaces.sorted { $0.name < $1.name }, ssid)
    }

    /// IP del router. Vía SystemConfiguration, no requiere shell-out.
    func captureGatewayIP() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "BGInfoMac" as CFString, nil, nil),
              let dict = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            return nil
        }
        return dict["Router"] as? String
    }

    /// Nombre BSD (ej. "en0", "utun4") de la interfaz que actualmente tiene
    /// la ruta por defecto. Cuando hay una VPN conectada, casi siempre pasa
    /// a ser el túnel (utunN) — es la forma más confiable de identificarlo,
    /// ya que las apps de VPN crean ese utun dinámicamente al conectar y no
    /// queda expuesto de antemano en la configuración de red guardada.
    func capturePrimaryInterfaceName() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "BGInfoMac" as CFString, nil, nil),
              let dict = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            return nil
        }
        return dict["PrimaryInterface"] as? String
    }

    /// Direcciones IPv4 primero (más legibles), preservando el orden
    /// relativo dentro de cada familia — el sort de Swift es estable.
    func captureDNSServers() -> [String] {
        guard let store = SCDynamicStoreCreate(nil, "BGInfoMac" as CFString, nil, nil),
              let dict = SCDynamicStoreCopyValue(store, "State:/Network/Global/DNS" as CFString) as? [String: Any] else {
            return []
        }
        let servers = dict["ServerAddresses"] as? [String] ?? []
        return servers.sorted { !$0.contains(":") && $1.contains(":") }
    }

    /// Nombre del servicio de VPN actualmente conectado, si lo hay. Casi
    /// todos los clientes de VPN modernos (Surfshark, NordVPN, Tailscale,
    /// WireGuard, Cisco AnyConnect, etc.) usan NetworkExtension, que registra
    /// un SCNetworkService de tipo "VPN" — el mismo mecanismo que usa
    /// `scutil --nc list`. VPNs puramente por línea de comandos (sin pasar
    /// por NetworkExtension) no aparecen acá.
    func captureVPNProvider() -> String? {
        guard let prefs = SCPreferencesCreate(nil, "BGInfoMac" as CFString, nil),
              let currentSet = SCNetworkSetCopyCurrent(prefs),
              let services = SCNetworkSetCopyServices(currentSet) as? [SCNetworkService] else {
            return nil
        }

        let vpnInterfaceTypes: Set<String> = [
            "VPN",
            kSCNetworkInterfaceTypeIPSec as String,
            kSCNetworkInterfaceTypePPP as String,
            kSCNetworkInterfaceTypeL2TP as String
        ]

        for service in services {
            guard let interface = SCNetworkServiceGetInterface(service),
                  let interfaceType = SCNetworkInterfaceGetInterfaceType(interface) as String?,
                  vpnInterfaceTypes.contains(interfaceType),
                  let serviceID = SCNetworkServiceGetServiceID(service),
                  let connection = SCNetworkConnectionCreateWithServiceID(nil, serviceID, nil, nil) else {
                continue
            }
            if SCNetworkConnectionGetStatus(connection) == .connected {
                return SCNetworkServiceGetName(service) as String?
            }
        }
        return nil
    }

    /// Mide velocidad de bajada y subida contra el mismo endpoint público
    /// que usa speed.cloudflare.com — no hay API nativa de macOS para esto.
    /// Es una sola conexión (no multi-hilo como un speedtest "real"),
    /// pensada como estimación rápida bajo demanda, no una medición
    /// exhaustiva; por eso no se repite sola con el refresco automático.
    func runSpeedTest(completion: @escaping (_ downloadMbps: Double?, _ uploadMbps: Double?) -> Void) {
        measureDownloadSpeed { downloadMbps in
            self.measureUploadSpeed { uploadMbps in
                completion(downloadMbps, uploadMbps)
            }
        }
    }

    private func measureDownloadSpeed(completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=10000000") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        let start = Date()
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data, !data.isEmpty else {
                completion(nil)
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            guard elapsed > 0 else {
                completion(nil)
                return
            }
            completion(Double(data.count) * 8 / elapsed / 1_000_000)
        }
        task.resume()
    }

    private func measureUploadSpeed(completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://speed.cloudflare.com/__up") else {
            completion(nil)
            return
        }
        let payload = Data(count: 3_000_000)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        let start = Date()
        let task = URLSession.shared.uploadTask(with: request, from: payload) { _, response, error in
            guard error == nil, (response as? HTTPURLResponse)?.statusCode == 200 else {
                completion(nil)
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            guard elapsed > 0 else {
                completion(nil)
                return
            }
            completion(Double(payload.count) * 8 / elapsed / 1_000_000)
        }
        task.resume()
    }

    func fetchPublicIP(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.ipify.org") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.timeoutInterval = 5
        // Sesión efímera y descartable: `URLSession.shared` reutiliza conexiones
        // keep-alive entre llamadas, así que justo después de conectar/desconectar
        // una VPN podía reusar una conexión abierta por la interfaz anterior y
        // devolver la IP pública vieja en vez de volver a resolverla.
        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data, let ip = String(data: data, encoding: .utf8), !ip.isEmpty else {
                completion(nil)
                return
            }
            completion(ip.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        task.resume()
    }

    /// Geolocaliza una IP a país, y de paso extrae el proveedor de Internet
    /// (ISP) — el mismo servicio ya lo incluye en "connection.isp", así que
    /// no hace falta una segunda llamada de red. Usa un servicio gratuito
    /// sin API key; si falla o no hay datos, devuelve nil (no mostramos
    /// nada, como se pidió).
    func fetchCountryInfo(forIP ip: String, completion: @escaping (_ name: String?, _ code: String?, _ isp: String?) -> Void) {
        guard let url = URL(string: "https://ipwho.is/\(ip)") else {
            completion(nil, nil, nil)
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.timeoutInterval = 5
        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  (json["success"] as? Bool) != false,
                  let country = json["country"] as? String, !country.isEmpty else {
                completion(nil, nil, nil)
                return
            }
            let connection = json["connection"] as? [String: Any]
            let isp = connection?["isp"] as? String
            completion(country, json["country_code"] as? String, (isp?.isEmpty == false) ? isp : nil)
        }
        task.resume()
    }

    // MARK: - Helpers

    private func sysctlString(_ name: String) -> String? {
        var size: Int = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private func formattedUptime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func currentUsedMemory() -> UInt64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let used = (UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)) * pageSize
        return used
    }
}
