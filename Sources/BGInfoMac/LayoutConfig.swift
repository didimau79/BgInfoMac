import Foundation

enum SectionKind: String, Codable, CaseIterable {
    case system
    case hardware
    case storage
    case network
    case message
}

enum FieldKind: String, Codable {
    case hostName
    case userName
    case osVersion
    case dateTime
    case serialNumber
    case osBuild

    case macModel
    case chipName
    case uptime
    case ram
    case battery
    case cpuCores
    case gpu

    case wifiSSID
    case interfaces
    case vpnProvider
    case publicIP
    case ispProvider
    case gateway
    case dnsServers
}

struct FieldConfig: Codable, Identifiable, Equatable {
    var id: FieldKind
    var isVisible: Bool = true
}

struct SectionConfig: Codable, Identifiable, Equatable {
    var id: SectionKind
    var isVisible: Bool = true
    var isTitleVisible: Bool = true
    var fields: [FieldConfig] = []
    // Solo se usan en la sección .storage; no rompen configuraciones viejas
    // porque el decoder manual de abajo les da un valor por defecto.
    var includeExternalVolumes: Bool = true
    var includeNetworkVolumes: Bool = true

    init(id: SectionKind, isVisible: Bool = true, isTitleVisible: Bool = true, fields: [FieldConfig] = [],
         includeExternalVolumes: Bool = true, includeNetworkVolumes: Bool = true) {
        self.id = id
        self.isVisible = isVisible
        self.isTitleVisible = isTitleVisible
        self.fields = fields
        self.includeExternalVolumes = includeExternalVolumes
        self.includeNetworkVolumes = includeNetworkVolumes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(SectionKind.self, forKey: .id)
        isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        isTitleVisible = try container.decodeIfPresent(Bool.self, forKey: .isTitleVisible) ?? true
        fields = try container.decodeIfPresent([FieldConfig].self, forKey: .fields) ?? []
        includeExternalVolumes = try container.decodeIfPresent(Bool.self, forKey: .includeExternalVolumes) ?? true
        includeNetworkVolumes = try container.decodeIfPresent(Bool.self, forKey: .includeNetworkVolumes) ?? true
    }
}

struct LayoutConfig: Codable, Equatable {
    var sections: [SectionConfig]

    static let `default` = LayoutConfig(sections: [
        SectionConfig(id: .system, fields: [
            FieldConfig(id: .hostName),
            FieldConfig(id: .userName),
            FieldConfig(id: .osVersion),
            FieldConfig(id: .dateTime),
            FieldConfig(id: .serialNumber),
            FieldConfig(id: .osBuild)
        ]),
        SectionConfig(id: .hardware, fields: [
            FieldConfig(id: .macModel),
            FieldConfig(id: .chipName),
            FieldConfig(id: .uptime),
            FieldConfig(id: .ram),
            FieldConfig(id: .battery),
            FieldConfig(id: .cpuCores),
            FieldConfig(id: .gpu)
        ]),
        SectionConfig(id: .storage, fields: []),
        SectionConfig(id: .network, fields: [
            FieldConfig(id: .wifiSSID),
            FieldConfig(id: .interfaces),
            FieldConfig(id: .vpnProvider),
            FieldConfig(id: .publicIP),
            FieldConfig(id: .ispProvider),
            FieldConfig(id: .gateway),
            FieldConfig(id: .dnsServers)
        ]),
        SectionConfig(id: .message, isVisible: false, fields: [])
    ])

    func isFieldVisible(_ field: FieldKind) -> Bool {
        for section in sections where section.isVisible {
            if let match = section.fields.first(where: { $0.id == field }) {
                return match.isVisible
            }
        }
        return false
    }

    // Si en el futuro se agregan secciones/campos nuevos, esto asegura que
    // aparezcan para usuarios que ya tenían una configuración guardada.
    mutating func reconcileWithDefaults() {
        let defaultConfig = LayoutConfig.default
        for defaultSection in defaultConfig.sections where !sections.contains(where: { $0.id == defaultSection.id }) {
            sections.append(defaultSection)
        }
        for index in sections.indices {
            guard let defaultSection = defaultConfig.sections.first(where: { $0.id == sections[index].id }) else { continue }
            for defaultField in defaultSection.fields where !sections[index].fields.contains(where: { $0.id == defaultField.id }) {
                insertNewField(defaultField, intoSectionAt: index)
            }
        }
    }

    // Un campo nuevo se ubica de forma sensata SOLO la primera vez que
    // aparece (cuando el usuario ya tenía una configuración guardada sin
    // él) — a partir de ahí, si el usuario lo arrastra a otra posición,
    // reconcileWithDefaults() ya no lo va a volver a mover, porque esta
    // función solo corre para campos AUSENTES, nunca para uno que ya existe.
    private mutating func insertNewField(_ field: FieldConfig, intoSectionAt index: Int) {
        var fields = sections[index].fields
        switch field.id {
        case .vpnProvider:
            if let anchorIndex = fields.firstIndex(where: { $0.id == .publicIP }) {
                fields.insert(field, at: anchorIndex)
            } else {
                fields.append(field)
            }
        case .ispProvider:
            if let anchorIndex = fields.firstIndex(where: { $0.id == .publicIP }) {
                fields.insert(field, at: anchorIndex + 1)
            } else {
                fields.append(field)
            }
        default:
            fields.append(field)
        }
        sections[index].fields = fields
    }
}
