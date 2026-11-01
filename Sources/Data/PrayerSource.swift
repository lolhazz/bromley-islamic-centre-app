import Foundation

/// Where the app's prayer times come from. Holds the latest timetables and iqamah rules and answers
/// `schedule(for:)`: timetable if it has the day, otherwise the calculator, then the committee's iqamah rules.
/// Shared by the app and the widgets (each process keeps its own copy, saved in its own UserDefaults).
enum PrayerSource {
    private static let lock = NSLock()
    private static var timetables: [Int: PrayerTimetable] = [:]
    private static var rules: [Prayer: IqamahRule] = [:]
    private static var loaded = false

    /// Unit tests must not see whatever the simulator last downloaded, so the shared state stays out of them.
    /// They call the pure `schedule(for:timetables:rules:)` instead.
    static let isUnderTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    static func schedule(for day: Date) -> DaySchedule {
        let (t, r) = snapshot()
        return schedule(for: day, timetables: t, rules: r)
    }

    /// Pure form of `schedule(for:)`.
    static func schedule(for day: Date, timetables: [Int: PrayerTimetable], rules: [Prayer: IqamahRule]) -> DaySchedule {
        let cal = PrayerCalculator.london
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        let base = comps.year.flatMap { timetables[$0] }?.schedule(for: day) ?? PrayerCalculator.calculate(for: day)
        guard !rules.isEmpty else { return base }
        return DaySchedule(date: base.date, sunrise: base.sunrise, entries: base.entries.map { e in
            guard let rule = rules[e.prayer] else { return e }
            return PrayerEntry(prayer: e.prayer, adhan: e.adhan, iqamah: rule.resolve(adhan: e.adhan, day: comps, fallback: e.iqamah))
        })
    }

    /// Rules from the editor's JSON, keyed by lower-case prayer name. Unknown keys are ignored.
    static func parseRules(_ raw: [String: IqamahRule]?) -> [Prayer: IqamahRule] {
        var out: [Prayer: IqamahRule] = [:]
        for p in Prayer.allCases { if let r = raw?[p.rawValue.lowercased()] { out[p] = r } }
        return out
    }

    // MARK: Shared state

    static func install(timetable: PrayerTimetable) {
        guard !isUnderTest else { return }
        lock.lock(); defer { lock.unlock() }
        timetables[timetable.year] = timetable
    }

    static func install(rules raw: [String: IqamahRule]?) {
        guard !isUnderTest else { return }
        lock.lock(); defer { lock.unlock() }
        rules = parseRules(raw)
    }

    private static func snapshot() -> ([Int: PrayerTimetable], [Prayer: IqamahRule]) {
        if !isUnderTest, !loadedAlready() { PrayerFeed.loadSaved() }
        lock.lock(); defer { lock.unlock() }
        return (timetables, rules)
    }

    private static func loadedAlready() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if loaded { return true }
        loaded = true
        return false
    }
}
