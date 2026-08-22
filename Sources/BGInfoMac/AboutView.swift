import AppKit
import SwiftUI

struct AboutView: View {
    private let lang = Preferences.shared.appLanguage

    private static let donateURL = URL(string: "https://www.paypal.com/donate?business=YCFM5VYWEFVMY&no_recurring=0&currency_code=USD")!

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "BGInfoMac"
    }

    private var versionString: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "2"
        return "\(L(.versionLabel, lang)) \(shortVersion) (\(build))"
    }

    private var yearString: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(year)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text(appName)
                .font(.title2)
                .bold()

            Text(versionString)
                .font(.body)
                .foregroundColor(.secondary)

            Text(L(.aboutTagline, lang))
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(L(.developedByLabel, lang))
                .font(.callout)
                .foregroundColor(.secondary)

            Button {
                NSWorkspace.shared.open(Self.donateURL)
            } label: {
                Label(L(.donateButtonLabel, lang), systemImage: "heart.fill")
            }
            .buttonStyle(.link)
            .padding(.top, 2)

            Text("© \(yearString) \(appName)")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(28)
        .frame(width: 300)
    }
}
