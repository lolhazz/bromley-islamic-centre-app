import Foundation

/// Downloads and saves the prayer timetable and the committee's iqamah rules, and hands them to `PrayerSource`.
/// Used by the app and by the widgets (the widget process cannot read the app's storage, so it fetches its own).
/// Everything fails quietly: with nothing saved, `PrayerSource` falls back to the calculated times.
enum PrayerFeed {
    /// The committee editor's site (see `admin/`). It holds the API key; the app never does.
    static let baseURL = URL(string: "https://bic-app-admin-hoodboyzt1-1429s-projects.vercel.app")!

    private static let tableKey = "prayerTimetable-"      // + year
    private static let fetchedKey = "prayerTimetableAt-"  // + year
    private static let triedKey = "prayerTimetableTried-" // + year
    private static let rulesKey = "iqamahRules"
    private static let refetchAfter: TimeInterval = 24 * 3600
    private static let retryAfter: TimeInterval = 3600

    private static var defaults: UserDefaults { .standard }

    /// Put whatever was saved last time into `PrayerSource`.
    static func loadSaved(now: Date = .now) {
        let year = PrayerCalculator.london.component(.year, from: now)
        for y in (year - 1)...(year + 1) {
            if let data = defaults.data(forKey: tableKey + String(y)),
               let table = try? JSONDecoder().decode(PrayerTimetable.self, from: data), table.year == y {
                PrayerSource.install(timetable: table)
            }
        }
        if let data = defaults.data(forKey: rulesKey), let raw = try? JSONDecoder().decode([String: IqamahRule].self, from: data) {
            PrayerSource.install(rules: raw)
        }
    }

    /// Use these iqamah rules now and keep them for next launch. nil clears them (back to the usual gaps).
    static func setRules(_ raw: [String: IqamahRule]?) {
        PrayerSource.install(rules: raw)
        guard !PrayerSource.isUnderTest else { return }
        if let raw, let data = try? JSONEncoder().encode(raw) { defaults.set(data, forKey: rulesKey) }
        else { defaults.removeObject(forKey: rulesKey) }
    }

    /// Years worth having: this one, and next year once December is close.
    static func yearsWanted(now: Date) -> [Int] {
        let c = PrayerCalculator.london.dateComponents([.year, .month], from: now)
        let year = c.year ?? 2026
        return (c.month ?? 1) >= 11 ? [year, year + 1] : [year]
    }

    /// Fetch any wanted year that is missing or older than a day. Returns true if a new timetable arrived.
    @discardableResult
    static func refreshTimes(now: Date = .now) async -> Bool {
        var changed = false
        for year in yearsWanted(now: now) {
            let have = defaults.data(forKey: tableKey + String(year)) != nil
            guard shouldFetch(have: have, fetchedAt: defaults.object(forKey: fetchedKey + String(year)) as? Date,
                              triedAt: defaults.object(forKey: triedKey + String(year)) as? Date, now: now) else { continue }
            defaults.set(now, forKey: triedKey + String(year))
            guard let table = await fetchTimetable(year: year) else { continue }
            PrayerSource.install(timetable: table)
            if let data = try? JSONEncoder().encode(table) {
                defaults.set(data, forKey: tableKey + String(year))
                defaults.set(now, forKey: fetchedKey + String(year))
            }
            changed = true
        }
        return changed
    }

    /// A saved timetable is refreshed daily. A failed attempt (for example next year's timetable is not published yet)
    /// is not repeated for an hour.
    static func shouldFetch(have: Bool, fetchedAt: Date?, triedAt: Date?, now: Date) -> Bool {
        if let triedAt, now.timeIntervalSince(triedAt) < retryAfter { return false }
        if have, let fetchedAt, now.timeIntervalSince(fetchedAt) < refetchAfter { return false }
        return true
    }

    /// Widgets only: the app gets the rules through `ConfigStore`. Fetches the config and keeps just the iqamah rules.
    static func refreshRules() async {
        struct Partial: Decodable { var iqamah: [String: IqamahRule]? }
        var request = URLRequest(url: baseURL.appendingPathComponent("api/config"), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let cfg = try? JSONDecoder().decode(Partial.self, from: data) else { return }
        setRules(cfg.iqamah)
    }

    static func fetchTimetable(year: Int) async -> PrayerTimetable? {
        var comps = URLComponents(url: baseURL.appendingPathComponent("api/times"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "year", value: String(year))]
        var request = URLRequest(url: comps.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return decodeTimetable(data, year: year)
    }

    /// A timetable is only used whole: right year, a full year of days, every time readable.
    static func decodeTimetable(_ data: Data, year: Int) -> PrayerTimetable? {
        guard let table = try? JSONDecoder().decode(PrayerTimetable.self, from: data), table.year == year else { return nil }
        let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        guard table.days.count == (isLeap ? 366 : 365) else { return nil }
        let ok = table.days.values.allSatisfy { d in
            [d.fajr, d.sunrise, d.dhuhr, d.asr, d.maghrib, d.isha].allSatisfy { IqamahRule.hourMinute($0) != nil }
        }
        return ok ? table : nil
    }
}
