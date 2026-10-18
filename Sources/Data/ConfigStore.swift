import Foundation

/// Shape of the online config file the committee edits. Every field is optional:
/// anything missing falls back to the built-in value in `Content`.
struct RemoteConfig: Codable {
    var jumuah: [JumuahSlot]?
    var venueBanner: String?
    var announcements: [Announcement]?
    var events: [EventItem]?
    /// First day of Ramadan as "yyyy-MM-dd". Overrides the calendar calculation (moon sighting).
    var ramadanStart: String?
    /// Taraweeh / iftar details to show on the Ramadan card.
    var ramadanNote: String?
}

/// Live content: bundled defaults, overridden by the last good online copy.
/// The online file is fetched at launch and whenever the app returns to the foreground.
@MainActor
final class ConfigStore: ObservableObject {
    @Published private(set) var jumuah = Content.jumuah
    @Published private(set) var venueBanner = Content.venueBanner
    @Published private(set) var announcements = Content.announcements
    @Published private(set) var events = Content.events
    @Published private(set) var ramadanStart: String?
    @Published private(set) var ramadanNote: String?
    @Published private(set) var lastUpdated: Date?

    /// Hosted JSON the committee edits through the admin page (see `admin/`). nil = bundled content only.
    static let configURL = URL(string: "https://bic-app-admin-hoodboyzt1-1429s-projects.vercel.app/api/config")

    private static let cacheKey = "remoteConfigCache"
    private static let dateKey = "remoteConfigDate"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let cfg = try? JSONDecoder().decode(RemoteConfig.self, from: data) {
            apply(cfg)
            lastUpdated = UserDefaults.standard.object(forKey: Self.dateKey) as? Date
        }
    }

    func refresh() async {
        guard let url = Self.configURL else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let cfg = try? JSONDecoder().decode(RemoteConfig.self, from: data) else { return }
        apply(cfg)
        lastUpdated = .now
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
        UserDefaults.standard.set(lastUpdated, forKey: Self.dateKey)
    }

    private func apply(_ c: RemoteConfig) {
        jumuah = (c.jumuah?.isEmpty == false ? c.jumuah : nil) ?? Content.jumuah
        venueBanner = c.venueBanner ?? Content.venueBanner
        announcements = c.announcements ?? Content.announcements
        events = c.events ?? Content.events
        ramadanStart = c.ramadanStart
        ramadanNote = c.ramadanNote
    }
}
