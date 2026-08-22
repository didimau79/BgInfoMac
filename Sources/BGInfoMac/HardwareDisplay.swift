import Foundation

enum HardwareDisplay {
    static func cpuCoresText(performance: Int?, efficiency: Int?, total: Int, lang: AppLanguage) -> String {
        if let performance = performance, let efficiency = efficiency {
            return "\(performance)P + \(efficiency)E"
        }
        return "\(total) \(L(.coresUnit, lang))"
    }

    static func gpuText(name: String, coreCount: Int?, lang: AppLanguage) -> String {
        guard let coreCount = coreCount else { return name }
        return "\(name) (\(coreCount) \(L(.coresUnit, lang)))"
    }

    static func batteryText(percentage: Int?, isCharging: Bool, healthPercent: Int?, cycleCount: Int?, lang: AppLanguage) -> String? {
        guard let percentage = percentage else { return nil }
        var text = "\(percentage)%"
        if isCharging { text += " ⚡" }
        if let health = healthPercent {
            text += " · \(health)% \(L(.batteryHealthLabel, lang))"
        }
        if let cycles = cycleCount {
            text += " · \(cycles) \(L(.batteryCyclesLabel, lang))"
        }
        return text
    }

    static func joinedList(_ items: [String]) -> String? {
        guard !items.isEmpty else { return nil }
        return items.joined(separator: ", ")
    }
}
