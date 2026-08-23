import AppKit
import SwiftUI

// SwiftUI's `.help()` no siempre dispara el tooltip dentro del contenido de
// un NSPopover (depende de mouse-moved tracking que el popover no siempre
// reenvía). Usamos el tooltip nativo de AppKit (NSView.toolTip), que es
// mucho más confiable en este contexto.
private struct NativeTooltip: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.toolTip = text
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = text
    }
}

private extension View {
    func nativeTooltip(_ text: String) -> some View {
        background(NativeTooltip(text: text))
    }
}

private enum SpeedTestState: Equatable {
    case idle
    case running
    case done(down: Double, up: Double)
    case failed
}

struct MenuPopoverView: View {
    let snapshot: SystemSnapshot
    let prefs: Preferences
    let showDonationPrompt: Bool
    private let info = SystemInfoProvider()

    private static let donateURL = URL(string: "https://www.paypal.com/donate?business=YCFM5VYWEFVMY&no_recurring=0&currency_code=USD")!

    @State private var donationPromptDismissedThisSession = false
    @State private var batteryPulseAnimating = false
    @State private var speedTestState: SpeedTestState = .idle

    private var lang: AppLanguage { prefs.appLanguage }

    private var shouldShowDonationBanner: Bool {
        showDonationPrompt && !donationPromptDismissedThisSession
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(prefs.menuLayout.sections) { section in
                if section.isVisible {
                    sectionView(section)
                }
            }

            if shouldShowDonationBanner {
                donationBanner
            }
        }
        .padding(14)
        .frame(minWidth: 260, alignment: .leading)
    }

    /// Se pide, como máximo, una vez por día (ver
    /// `Preferences.shouldShowDonationPromptToday`). ⌘⇧D la desactiva para
    /// siempre — el botón de donar sigue disponible en "Acerca de".
    private var donationBanner: some View {
        VStack(alignment: .leading, spacing: 2) {
            Divider()
                .padding(.top, 2)
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L(.donationPromptText, lang))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Button(L(.donateButtonLabel, lang)) {
                        NSWorkspace.shared.open(Self.donateURL)
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                }
                Spacer(minLength: 4)
                Button {
                    prefs.donationPromptDisabled = true
                    donationPromptDismissedThisSession = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .help(L(.donationPromptDisableHint, lang))
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: SectionConfig) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if section.isTitleVisible {
                Text(sectionLabel(section.id, lang).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
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
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(snapshot.volumes.filter { shouldShowVolume($0, section) }) { vol in
                        storageBar(vol)
                    }
                }
            case .message:
                if !prefs.menuCustomMessageText.isEmpty {
                    Text(prefs.menuCustomMessageText)
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                }
            }
        }
    }

    /// Cuando hay VPN conectada, sus datos (nombre, IP del túnel, IP
    /// pública, gateway y DNS) se muestran agrupados aparte, separados de
    /// la red propia por una línea divisoria.
    @ViewBuilder
    private func networkSectionBody(_ section: SectionConfig) -> some View {
        if snapshot.interfaces.isEmpty {
            Text(L(.noNetworkConnection, lang))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
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
        let localKinds: Set<FieldKind> = [.wifiSSID, .interfaces]
        let internetKinds: Set<FieldKind> = [.publicIP, .ispProvider, .gateway, .dnsServers]
        let localFields = section.fields.filter { $0.isVisible && localKinds.contains($0.id) }

        ForEach(localFields) { field in
            fieldRow(field.id)
        }

        // Separa lo "local" (Wi-Fi, interfaces) de lo que depende de la
        // conexión a Internet (IP pública, gateway, DNS, VPN si hay).
        if !localFields.isEmpty {
            Divider()
                .padding(.vertical, 2)
        }

        if vpnConnected {
            if isFieldVisible(.ispProvider) { fieldRow(.ispProvider) }
            fieldRow(.vpnProvider)
            if let tunnelIP = snapshot.vpnTunnelIP {
                row(L(.fieldVPNTunnelIP, lang), tunnelIP)
            }
            if isFieldVisible(.publicIP) { fieldRow(.publicIP) }
            if isFieldVisible(.gateway) { fieldRow(.gateway) }
            if isFieldVisible(.dnsServers) { fieldRow(.dnsServers) }
        } else {
            ForEach(section.fields.filter { $0.isVisible && internetKinds.contains($0.id) }) { field in
                fieldRow(field.id)
            }
        }

        speedTestRow
    }

    /// Sin API nativa para esto — mide bajada/subida bajo demanda contra un
    /// endpoint público. El mismo botón sirve para repetir la medición.
    private var speedTestRow: some View {
        HStack(spacing: 8) {
            Button(L(.speedTestButtonLabel, lang)) {
                runSpeedTestIfNeeded()
            }
            .font(.system(size: 10.5))
            .controlSize(.mini)
            .disabled(speedTestState == .running)

            speedTestResultText

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var speedTestResultText: some View {
        switch speedTestState {
        case .idle:
            EmptyView()
        case .running:
            Text(L(.speedTestRunningLabel, lang))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        case .done(let down, let up):
            Text(String(format: L(.speedTestResultFormat, lang), down, up))
                .font(.system(size: 11))
                .foregroundColor(.green)
        case .failed:
            Text(L(.speedTestFailedLabel, lang))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private func runSpeedTestIfNeeded() {
        guard speedTestState != .running else { return }
        speedTestState = .running
        info.runSpeedTest { down, up in
            DispatchQueue.main.async {
                if let down = down, let up = up {
                    speedTestState = .done(down: down, up: up)
                } else {
                    speedTestState = .failed
                }
            }
        }
    }

    @ViewBuilder
    private func fieldRow(_ kind: FieldKind) -> some View {
        switch kind {
        case .hostName: row(fieldLabel(kind, lang), snapshot.hostName)
        case .userName: row(fieldLabel(kind, lang), snapshot.userName)
        case .osVersion: row(fieldLabel(kind, lang), snapshot.osVersion)
        case .dateTime: row(fieldLabel(kind, lang), snapshot.dateString)
        case .serialNumber:
            if !snapshot.serialNumber.isEmpty {
                row(fieldLabel(kind, lang), snapshot.serialNumber)
            }
        case .osBuild:
            if !snapshot.osBuild.isEmpty {
                row(fieldLabel(kind, lang), snapshot.osBuild)
            }
        case .macModel: row(fieldLabel(kind, lang), snapshot.macModel)
        case .chipName: row(fieldLabel(kind, lang), snapshot.chipName)
        case .uptime: row(fieldLabel(kind, lang), snapshot.uptimeString)
        case .ram: ramBar()
        case .battery:
            if let percentage = snapshot.batteryPercentage {
                batteryBar(percentage: percentage)
            }
        case .cpuCores:
            row(fieldLabel(kind, lang), HardwareDisplay.cpuCoresText(performance: snapshot.cpuPerformanceCores, efficiency: snapshot.cpuEfficiencyCores, total: snapshot.cpuTotalCores, lang: lang))
        case .gpu:
            row(fieldLabel(kind, lang), HardwareDisplay.gpuText(name: snapshot.gpuName, coreCount: snapshot.gpuCoreCount, lang: lang))
        case .wifiSSID:
            if let ssid = snapshot.wifiSSID {
                row(fieldLabel(kind, lang), ssid)
            } else if isWifiUnauthorizedWarningNeeded {
                Text(L(.wifiPermissionWarningShort, lang))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        case .interfaces:
            ForEach(snapshot.interfaces) { iface in
                row(interfaceLabel(iface), iface.address)
            }
        case .publicIP:
            if let publicIP = snapshot.publicIP {
                publicIPRow(publicIP)
            }
        case .ispProvider:
            if let isp = snapshot.ispProvider {
                row(fieldLabel(kind, lang), isp)
            }
        case .gateway:
            if let gateway = snapshot.gatewayIP {
                row(fieldLabel(kind, lang), gateway)
            }
        case .dnsServers:
            if !snapshot.dnsServers.isEmpty {
                dnsRow()
            }
        case .vpnProvider:
            if let vpnProvider = snapshot.vpnProvider {
                row(fieldLabel(kind, lang), vpnProvider)
            }
        }
    }

    /// Muestra "IP (CÓDIGO 🏳)" con la bandera como su propio elemento, para
    /// poder colgarle un tooltip con el nombre completo del país sin afectar
    /// al resto del texto.
    private func publicIPRow(_ ip: String) -> some View {
        let countryText = CountryDisplay.displayText(countryName: snapshot.publicIPCountryName, countryCode: snapshot.publicIPCountryCode)
        let flag = CountryDisplay.flagEmoji(countryCode: snapshot.publicIPCountryCode)

        return HStack(alignment: .top, spacing: 8) {
            Text(fieldLabel(.publicIP, lang))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: 0) {
                if let countryText = countryText {
                    Text("\(ip) (\(countryText)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                    if let flag = flag {
                        Text(" \(flag)")
                            .font(.system(size: 12))
                            .nativeTooltip(snapshot.publicIPCountryName ?? countryText)
                    }
                    Text(")")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                } else {
                    Text(ip)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .textSelection(.enabled)

            Spacer(minLength: 0)
        }
    }

    /// Muestra solo el primer servidor DNS (ya viene con IPv4 primero desde
    /// `captureDNSServers`) y, si hay más, un "+N" con un tooltip propio
    /// listando el resto, uno por renglón.
    private func dnsRow() -> some View {
        let servers = snapshot.dnsServers
        let first = servers.first ?? ""
        let remaining = servers.dropFirst()

        return HStack(alignment: .top, spacing: 8) {
            Text(fieldLabel(.dnsServers, lang))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: 4) {
                Text(first)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.primary)
                if !remaining.isEmpty {
                    Text(String(format: L(.dnsMoreSuffix, lang), remaining.count))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .nativeTooltip(remaining.joined(separator: "\n"))
                }
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .textSelection(.enabled)

            Spacer(minLength: 0)
        }
    }

    private var isWifiUnauthorizedWarningNeeded: Bool {
        !WifiAuthorization.shared.isAuthorized && snapshot.interfaces.contains { $0.kind == .wifi }
    }

    /// Umbrales estándar de monitoreo (los mismos que usan herramientas como
    /// Nagios/Zabbix por defecto): normal por debajo de 80% de uso,
    /// advertencia entre 80-90%, crítico por encima de 90%.
    private func usageBarColor(fraction: Double) -> Color {
        switch fraction {
        case ..<0.8: return .accentColor
        case ..<0.9: return .orange
        default: return .red
        }
    }

    private func ramBar() -> some View {
        let fraction = snapshot.totalRAMBytes > 0
            ? Double(snapshot.usedRAMBytes) / Double(snapshot.totalRAMBytes)
            : 0
        return HStack(spacing: 8) {
            Text(fieldLabel(.ram, lang))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usageBarColor(fraction: fraction))
                        .frame(width: geo.size.width * CGFloat(min(max(fraction, 0), 1)))
                }
            }
            .frame(height: 8)
            .nativeTooltip("\(info.formattedBytes(snapshot.usedRAMBytes)) / \(info.formattedBytes(snapshot.totalRAMBytes))")
        }
    }

    /// Azul (igual que la RAM) de 100 a 50%, naranja de 49 a 15%, rojo de
    /// 14 a 0% — para que el color de la barra anticipe visualmente cuándo
    /// queda poca batería. Salud y ciclos de carga van en el tooltip.
    private func batteryBar(percentage: Int) -> some View {
        let fraction = Double(percentage) / 100
        let color: Color = percentage >= 50 ? .accentColor : (percentage >= 15 ? .orange : .red)
        let isCharging = snapshot.batteryIsCharging
        let tooltip = HardwareDisplay.batteryText(percentage: snapshot.batteryPercentage, isCharging: isCharging, healthPercent: snapshot.batteryHealthPercent, cycleCount: snapshot.batteryCycleCount, timeRemainingMinutes: snapshot.batteryTimeRemainingMinutes, lang: lang) ?? ""

        return HStack(spacing: 8) {
            Text(fieldLabel(.battery, lang))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(max(fraction, 0), 1)))
                        // Pulso suave mientras carga — anticipa visualmente
                        // que el equipo está enchufado sin competir con el
                        // color que indica el nivel de batería.
                        .opacity(isCharging && batteryPulseAnimating ? 0.55 : 1)
                }
            }
            .frame(height: 8)
            .nativeTooltip(tooltip)

            if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                    .transition(.opacity.combined(with: .scale(scale: 0.5)))
            }
        }
        // Al conectar/desconectar, el rayo aparece/desaparece y la barra
        // achica/recupera su ancho en el mismo movimiento animado — en vez
        // de reservarle un espacio fijo que la dejaría permanentemente más
        // angosta que las demás barras (RAM, almacenamiento).
        .animation(.easeInOut(duration: 0.35), value: isCharging)
        .onAppear { startBatteryPulseIfNeeded() }
        .onChange(of: isCharging) { charging in
            if charging {
                startBatteryPulseIfNeeded()
            } else {
                withAnimation(.easeOut(duration: 0.3)) { batteryPulseAnimating = false }
            }
        }
    }

    private func startBatteryPulseIfNeeded() {
        guard snapshot.batteryIsCharging, !batteryPulseAnimating else { return }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            batteryPulseAnimating = true
        }
    }

    private func storageTooltip(_ vol: VolumeInfo) -> String {
        let usedFree = String(format: L(.storageUsedFreeTooltip, lang), info.formattedBytes(vol.usedBytes), info.formattedBytes(vol.availableBytes))
        guard let format = vol.formatDescription, !format.isEmpty else { return usedFree }
        return "\(usedFree) — \(format)"
    }

    private func storageBar(_ vol: VolumeInfo) -> some View {
        HStack(spacing: 8) {
            Text(vol.name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usageBarColor(fraction: vol.usedFraction))
                        .frame(width: geo.size.width * CGFloat(min(max(vol.usedFraction, 0), 1)))
                }
            }
            .frame(height: 8)
            .nativeTooltip(storageTooltip(vol))
        }
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
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 0)
        }
    }
}
