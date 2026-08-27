import AppKit
import SwiftUI

struct HelpView: View {
    private static let donateURL = URL(string: "https://www.paypal.com/donate?business=YCFM5VYWEFVMY&no_recurring=0&currency_code=USD")!
    private static let githubURL = URL(string: "https://github.com/didimau79/BgInfoMac")!

    private let lang: AppLanguage
    private let topics: [HelpTopic]

    @State private var searchText = ""
    @State private var selection: Int?

    init() {
        let lang = Preferences.shared.appLanguage
        self.lang = lang
        let topics = HelpContent.topics(for: lang)
        self.topics = topics
        _selection = State(initialValue: topics.first?.id)
    }

    private var filteredTopics: [HelpTopic] {
        guard !searchText.isEmpty else { return topics }
        let query = searchText.lowercased()
        return topics.filter { topic in
            topic.title.lowercased().contains(query) || topic.body.contains { $0.lowercased().contains(query) }
        }
    }

    private var selectedTopic: HelpTopic? {
        topics.first { $0.id == selection }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(L(.helpSearchPlaceholder, lang), text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)

                Divider()

                List(filteredTopics, selection: $selection) { topic in
                    Text(topic.title)
                        .tag(topic.id)
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        } detail: {
            if let topic = selectedTopic {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(topic.title)
                            .font(.title2)
                            .bold()

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(topic.body.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }

                        if topic.id == HelpContent.introductionTopicIndex {
                            Button {
                                NSWorkspace.shared.open(Self.githubURL)
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                                .font(.system(size: 14, weight: .medium))
                                        )

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(L(.githubLinkTitle, lang))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(Self.githubURL.host.map { $0 + Self.githubURL.path } ?? Self.githubURL.absoluteString)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer(minLength: 0)

                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)

                            Button {
                                NSWorkspace.shared.open(Self.donateURL)
                            } label: {
                                Label(L(.donateButtonLabel, lang), systemImage: "heart.fill")
                            }
                            .padding(.top, 4)
                        }

                        if topic.id == HelpContent.permissionsTopicIndex {
                            Button(L(.openSystemSettingsButton, lang)) {
                                WifiAuthorization.shared.openSystemSettings()
                            }
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
            } else {
                Text(L(.helpNoSelection, lang))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 680, minHeight: 460)
    }
}
