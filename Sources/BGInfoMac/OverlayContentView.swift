import SwiftUI

struct OverlayContentView: View {
    let snapshot: SystemSnapshot
    let prefs: Preferences
    let info = SystemInfoProvider()

    private var lang: AppLanguage { prefs.appLanguage }
    private var textColor: Color { Color(hex: prefs.textColorHex, fallback: .white) }
    private var labelColor: Color { textColor.opacity(0.75) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(prefs.layout.sections) { section in
                if section.isVisible {
                    sectionView(section)
                }
            }
        }
        .padding(10)
        .font(.system(size: prefs.fontSize, weight: .regular, design: .monospaced))
        .foregroundColor(textColor)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: prefs.backgroundColorHex, fallback: .black).opacity(prefs.backgroundOpacity))
        )
    }

    private func sectionTitle(_ id: SectionKind) -> String {
        switch id {
        case .system: return L(.sectionSystem, lang)
        case .hardware: return L(.sectionHardware, lang)
        case .storage: return L(.sectionStorage, lang)
        case .network: return L(.sectionNetwork, lang)
        case .message: return L(.sectionMessage, lang)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: SectionConfig) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if section.isTitleVisible {
                Text(sectionTitle(section.id).uppercased())
                    .font(.system(size: prefs.fontSize + 1, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)
                    .shadow(color: .black, radius: 3)
                    .padding(.bottom, 1)
            }

            switch section.id {
            case .system, .hardware:
                ForEach(section.fields.filter { $0.isVisible }) { field in
                    fieldRow(field.id)
                }
            case .network:
                networkSectionBody(section)
            case .storage:
                ForEach(snapshot.volumes.filter { shouldShowVolume($0, section) }) { vol in
                    row(vol.name, "\(info.formattedBytes(vol.usedBytes))/\(info.formattedBytes(vol.totalBytes))")
                }
            case .message:
                if !prefs.customMessageText.isEmpty {
                    Text(prefs.customMessageText)
                        .foregroundColor(textColor)
                        .shadow(color: .black, radius: 3)
                }
            }
        }
        .padding(.bottom, 4)
    }

    /// Cuando hay VPN conectada, sus datos (nombre, IP del túnel, IP
    /// pública, gateway y DNS) se muestran agrupados aparte, separados de
    /// la red propia por una línea divisoria.
    @ViewBuilder
    private func networkSectionBody(_ section: SectionConfig) -> some View {
        if snapshot.interfaces.isEmpty {
            Text(L(.noNetworkConnection, lang))
                .foregroundColor(labelColor)
                .shadow(color: .black, radius: 3)
        } else {
            networkFieldsBody(section)
        }
    }

    @ViewBuilder
    private func networkFieldsBody(_ section: SectionConfig) -> some View {
        let isFieldVisible: (FieldKind) -> Bool = { kind in
            section.fields.first(where: { $0.id == kind })?.isVisible ?? true
        }
        let vpnConnected = snapshot.vpnProvider != nil && isFieldVisible(.vpnProvider)
        let vpnGroupedKinds: Set<FieldKind> = [.vpnProvider, .publicIP, .ispProvider, .gateway, .dnsServers]

        ForEach(section.fields.filter { $0.isVisible && !(vpnConnected && vpnGroupedKinds.contains($0.id)) }) { field in
            fieldRow(field.id)
        }

        if vpnConnected {
            Rectangle()
                .fill(textColor.opacity(0.25))
                .frame(height: 1)
                .padding(.vertical, 2)

            if isFieldVisible(.ispProvider) { fieldRow(.ispProvider) }
            fieldRow(.vpnProvider)
            if let tunnelIP = snapshot.vpnTunnelIP {
                row(L(.fieldVPNTunnelIP, lang), tunnelIP)
            }
            if isFieldVisible(.publicIP) { fieldRow(.publicIP) }
            if isFieldVisible(.gateway) { fieldRow(.gateway) }
            if isFieldVisible(.dnsServers) { fieldRow(.dnsServers) }
        }
    }

    @ViewBuilder
    private func fieldRow(_ kind: FieldKind) -> some View {
        switch kind {
        case .hostName: row(L(.fieldHostName, lang), snapshot.hostName)
        case .userName: row(L(.fieldUserName, lang), snapshot.userName)
        case .osVersion: row(L(.fieldOSVersion, lang), snapshot.osVersion)
        case .dateTime: row(L(.fieldDateTime, lang), snapshot.dateString)
        case .serialNumber:
            if !snapshot.serialNumber.isEmpty {
                row(L(.fieldSerialNumber, lang), snapshot.serialNumber)
            }
        case .osBuild:
            if !snapshot.osBuild.isEmpty {
                row(L(.fieldOSBuild, lang), snapshot.osBuild)
            }
        case .macModel: row(L(.fieldMacModel, lang), snapshot.macModel)
        case .chipName: row(L(.fieldChipName, lang), snapshot.chipName)
        case .uptime: row(L(.fieldUptime, lang), snapshot.uptimeString)
        case .ram: row(L(.fieldRAM, lang), "\(info.formattedBytes(snapshot.usedRAMBytes))/\(info.formattedBytes(snapshot.totalRAMBytes))")
        case .battery:
            if let batteryText = HardwareDisplay.batteryText(percentage: snapshot.batteryPercentage, isCharging: snapshot.batteryIsCharging, healthPercent: snapshot.batteryHealthPercent, cycleCount: snapshot.batteryCycleCount, lang: lang) {
                row(L(.fieldBattery, lang), batteryText)
            }
        case .cpuCores:
            row(L(.fieldCPUCores, lang), HardwareDisplay.cpuCoresText(performance: snapshot.cpuPerformanceCores, efficiency: snapshot.cpuEfficiencyCores, total: snapshot.cpuTotalCores, lang: lang))
        case .gpu:
            row(L(.fieldGPU, lang), HardwareDisplay.gpuText(name: snapshot.gpuName, coreCount: snapshot.gpuCoreCount, lang: lang))
        case .wifiSSID:
            if let ssid = snapshot.wifiSSID {
                row(L(.fieldWifiSSID, lang), ssid)
            } else if isWifiUnauthorizedWarningNeeded {
                Text(L(.wifiPermissionWarningShort, lang))
                    .font(.system(size: max(prefs.fontSize - 2, 8)))
                    .foregroundColor(labelColor)
                    .shadow(color: .black, radius: 3)
            }
        case .interfaces:
            ForEach(snapshot.interfaces) { iface in
                row(interfaceLabel(iface), iface.address)
            }
        case .publicIP:
            if let publicIP = snapshot.publicIP {
                row(L(.fieldPublicIP, lang), CountryDisplay.fullDisplayText(ip: publicIP, countryName: snapshot.publicIPCountryName, countryCode: snapshot.publicIPCountryCode))
            }
        case .ispProvider:
            if let isp = snapshot.ispProvider {
                row(L(.fieldISPProvider, lang), isp)
            }
        case .gateway:
            if let gateway = snapshot.gatewayIP {
                row(L(.fieldGateway, lang), gateway)
            }
        case .dnsServers:
            if let dnsText = HardwareDisplay.joinedList(snapshot.dnsServers) {
                row(L(.fieldDNSServers, lang), dnsText)
            }
        case .vpnProvider:
            if let vpnProvider = snapshot.vpnProvider {
                row(L(.fieldVPNProvider, lang), vpnProvider)
            }
        }
    }

    private var isWifiUnauthorizedWarningNeeded: Bool {
        !WifiAuthorization.shared.isAuthorized && snapshot.interfaces.contains { $0.kind == .wifi }
    }

    private func shouldShowVolume(_ vol: VolumeInfo, _ section: SectionConfig) -> Bool {
        switch vol.kind {
        case .internalDisk: return true
        case .external: return section.includeExternalVolumes
        case .network: return section.includeNetworkVolumes
        }
    }

    private func interfaceLabel(_ iface: NetworkInterfaceInfo) -> String {
        switch iface.kind {
        case .wifi: return L(.interfaceWifiIP, lang)
        case .ethernet: return L(.interfaceEthernet, lang)
        case .other: return iface.name
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(label):")
                .foregroundColor(labelColor)
                .shadow(color: .black, radius: 3)
            Text(value)
                .foregroundColor(textColor)
                .shadow(color: .black, radius: 3)
        }
    }
}
