import Foundation

enum CountryDisplay {
    /// El nombre completo del país (ej. "Estados Unidos") suele ser
    /// demasiado largo para un renglón junto a la IP; usamos siempre el
    /// código ISO 3166-1 alpha-2 (ej. "US"), y solo caemos al nombre si por
    /// algún motivo el código no vino en la respuesta.
    static func displayText(countryName: String?, countryCode: String?) -> String? {
        if let code = countryCode, !code.isEmpty {
            return code.uppercased()
        }
        if let name = countryName, !name.isEmpty {
            return name
        }
        return nil
    }

    /// Convierte un código ISO 3166-1 alpha-2 (ej. "AR") al emoji de bandera
    /// correspondiente combinando los símbolos regionales Unicode.
    static func flagEmoji(countryCode: String?) -> String? {
        guard let code = countryCode?.uppercased(), code.count == 2 else { return nil }
        var scalars = String.UnicodeScalarView()
        for scalar in code.unicodeScalars {
            guard let value = UnicodeScalar(127397 + scalar.value) else { return nil }
            scalars.append(value)
        }
        return String(scalars)
    }

    /// "190.220.27.66 (AR 🇦🇷)" — o solo la IP si no se pudo geolocalizar.
    static func fullDisplayText(ip: String, countryName: String?, countryCode: String?) -> String {
        guard let text = displayText(countryName: countryName, countryCode: countryCode) else { return ip }
        if let flag = flagEmoji(countryCode: countryCode) {
            return "\(ip) (\(text) \(flag))"
        }
        return "\(ip) (\(text))"
    }
}
