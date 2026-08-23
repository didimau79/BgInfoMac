import AppKit
import SwiftUI
import UniformTypeIdentifiers

func sectionLabel(_ id: SectionKind, _ lang: AppLanguage) -> String {
    switch id {
    case .system: return L(.sectionSystem, lang)
    case .hardware: return L(.sectionHardware, lang)
    case .storage: return L(.sectionStorage, lang)
    case .network: return L(.sectionNetwork, lang)
    case .message: return L(.sectionMessage, lang)
    }
}

func fieldLabel(_ id: FieldKind, _ lang: AppLanguage) -> String {
    switch id {
    case .hostName: return L(.fieldHostName, lang)
    case .userName: return L(.fieldUserName, lang)
    case .osVersion: return L(.fieldOSVersion, lang)
    case .dateTime: return L(.fieldDateTime, lang)
    case .serialNumber: return L(.fieldSerialNumber, lang)
    case .osBuild: return L(.fieldOSBuild, lang)
    case .macModel: return L(.fieldMacModel, lang)
    case .chipName: return L(.fieldChipName, lang)
    case .uptime: return L(.fieldUptime, lang)
    case .ram: return L(.fieldRAM, lang)
    case .battery: return L(.fieldBattery, lang)
    case .cpuCores: return L(.fieldCPUCores, lang)
    case .gpu: return L(.fieldGPU, lang)
    case .wifiSSID: return L(.fieldWifiSSID, lang)
    case .interfaces: return L(.fieldInterfaces, lang)
    case .publicIP: return L(.fieldPublicIP, lang)
    case .gateway: return L(.fieldGateway, lang)
    case .dnsServers: return L(.fieldDNSServers, lang)
    case .vpnProvider: return L(.fieldVPNProvider, lang)
    case .ispProvider: return L(.fieldISPProvider, lang)
    }
}

private struct SectionRowView: View {
    @Binding var section: SectionConfig
    @Binding var customMessageText: String
    let language: AppLanguage
    let dragSource: DragSourceModifier<SectionConfig>
    @ObservedObject private var wifiAuth = WifiAuthorization.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                DragHandle()
                    .modifier(dragSource)
                Toggle(sectionLabel(section.id, language), isOn: $section.isVisible)
                    .font(.headline)
                Spacer()
                Toggle(L(.showTitleToggle, language), isOn: $section.isTitleVisible)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if section.isVisible {
                switch section.id {
                case .system, .hardware:
                    DragReorderableList(items: $section.fields) { $field, fieldDragSource in
                        HStack {
                            DragHandle()
                                .modifier(fieldDragSource)
                            Toggle(fieldLabel(field.id, language), isOn: $field.isVisible)
                        }
                        .padding(.leading, 22)
                    }
                case .network:
                    DragReorderableList(items: $section.fields) { $field, fieldDragSource in
                        HStack {
                            DragHandle()
                                .modifier(fieldDragSource)
                            Toggle(fieldLabel(field.id, language), isOn: $field.isVisible)
                        }
                        .padding(.leading, 22)
                    }
                    if wifiSSIDFieldVisible {
                        wifiPermissionNotice
                    }
                case .storage:
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L(.storageHint, language))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Toggle(L(.includeExternalVolumes, language), isOn: $section.includeExternalVolumes)
                        Toggle(L(.includeNetworkVolumes, language), isOn: $section.includeNetworkVolumes)
                    }
                    .padding(.leading, 22)
                case .message:
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L(.messagePlaceholder, language))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $customMessageText)
                            .frame(height: 50)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3)))
                    }
                    .padding(.leading, 22)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.08)))
    }

    private var wifiSSIDFieldVisible: Bool {
        section.fields.first(where: { $0.id == .wifiSSID })?.isVisible == true
    }

    @ViewBuilder
    private var wifiPermissionNotice: some View {
        if !wifiAuth.isAuthorized {
            VStack(alignment: .leading, spacing: 6) {
                Text(L(.wifiPermissionPrefsMessage, language))
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L(.openSystemSettingsButton, language)) {
                    WifiAuthorization.shared.openSystemSettings()
                }
                .font(.caption)
            }
            .padding(.leading, 22)
            .padding(.top, 4)
        }
    }
}

enum FieldsEditingTarget {
    case desktop
    case menuBar
}

private enum PrefsTab: Hashable {
    case fields
    case appearance
}

private struct PrefsContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct PreferencesView: View {
    @ObservedObject var vm: PreferencesViewModel
    @State private var editingTarget: FieldsEditingTarget = .desktop
    @State private var selectedTab: PrefsTab = .fields
    var onContentSizeChange: ((CGSize) -> Void)?

    var body: some View {
        TabView(selection: $selectedTab) {
            ScrollView {
                fieldsTab
                    .padding(16)
                    .background(sizeReporter)
            }
            .tabItem { Text(L(.tabFields, vm.language)) }
            .tag(PrefsTab.fields)

            ScrollView {
                appearanceTab
                    .padding(16)
                    .background(sizeReporter)
            }
            .tabItem { Text(L(.tabAppearance, vm.language)) }
            .tag(PrefsTab.appearance)
        }
        .onPreferenceChange(PrefsContentSizeKey.self) { size in
            guard size.width > 0, size.height > 0 else { return }
            onContentSizeChange?(size)
        }
        .frame(minWidth: 460, idealWidth: 480)
    }

    private var sizeReporter: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: PrefsContentSizeKey.self, value: proxy.size)
        }
    }

    private var isDesktopFieldsDisabled: Bool {
        editingTarget == .desktop && !vm.overlayVisible
    }

    private var fieldsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("", selection: $editingTarget) {
                Text(L(.targetDesktop, vm.language)).tag(FieldsEditingTarget.desktop)
                Text(L(.targetMenuBar, vm.language)).tag(FieldsEditingTarget.menuBar)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if editingTarget == .desktop {
                Toggle(L(.showOverlay, vm.language), isOn: $vm.overlayVisible)
                    .font(.subheadline)

                Picker(L(.displayTargetLabel, vm.language), selection: $vm.displayTarget) {
                    Text(L(.allDisplaysOption, vm.language)).tag(Preferences.allDisplaysTarget)
                    ForEach(vm.screens, id: \.localizedName) { screen in
                        Text(screen.localizedName).tag(screen.localizedName)
                    }
                }
                .pickerStyle(.menu)
            }

            DragReorderableList(
                items: editingTarget == .desktop ? $vm.layout.sections : $vm.menuLayout.sections
            ) { $section, sectionDragSource in
                SectionRowView(
                    section: $section,
                    customMessageText: editingTarget == .desktop ? $vm.customMessageText : $vm.menuCustomMessageText,
                    language: vm.language,
                    dragSource: sectionDragSource
                )
            }
            .disabled(isDesktopFieldsDisabled)
            .opacity(isDesktopFieldsDisabled ? 0.4 : 1.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(L(.launchAtLogin, vm.language), isOn: $vm.launchAtLogin)

            Picker(L(.languageLabel, vm.language), selection: $vm.language) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.nativeName).tag(lang)
                }
            }
            .pickerStyle(.menu)

            Picker(L(.appearanceLabel, vm.language), selection: $vm.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.label(vm.language)).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Divider()

            ColorPicker(L(.textColorLabel, vm.language), selection: $vm.textColor, supportsOpacity: false)
            ColorPicker(L(.backgroundColorLabel, vm.language), selection: $vm.backgroundColor, supportsOpacity: false)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(L(.backgroundOpacityLabel, vm.language)): \(Int(vm.backgroundOpacity * 100))%")
                Slider(value: $vm.backgroundOpacity, in: 0...1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(L(.fontSizeLabel, vm.language)): \(Int(vm.fontSize)) pt")
                Slider(value: $vm.fontSize, in: 9...20, step: 1)
            }

            Divider()

            Picker(L(.positionCornerLabel, vm.language), selection: $vm.corner) {
                ForEach(ScreenCorner.allCases, id: \.self) { corner in
                    Text(corner.label(vm.language)).tag(corner)
                }
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(L(.marginHorizontal, vm.language)): \(Int(vm.marginX)) pt")
                Slider(value: $vm.marginX, in: 0...400)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(L(.marginVertical, vm.language)): \(Int(vm.marginY)) pt")
                Slider(value: $vm.marginY, in: 0...400)
            }

            Divider()

            HStack {
                Button(L(.exportSettingsButton, vm.language)) { exportSettings() }
                Button(L(.importSettingsButton, vm.language)) { importSettings() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exportSettings() {
        guard let data = try? Preferences.shared.exportSettingsData() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "BGInfoMac-Settings.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url, options: .atomic)
            showAlert(title: L(.exportSettingsSuccessTitle, vm.language), message: L(.exportSettingsSuccessMessage, vm.language))
        } catch {
            NSLog("BGInfoMac: no se pudo exportar la configuración: \(error)")
        }
    }

    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            try Preferences.shared.importSettingsData(data)
            showAlert(title: L(.importSettingsSuccessTitle, vm.language), message: L(.importSettingsSuccessMessage, vm.language))
        } catch {
            showAlert(title: L(.importSettingsErrorTitle, vm.language), message: L(.importSettingsErrorMessage, vm.language))
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
