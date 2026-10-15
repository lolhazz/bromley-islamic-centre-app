import Foundation

enum RamadanState {
    case none
    case before(daysUntil: Int)
    case during(day: Int)
}

/// Ramadan awareness. Uses the Umm al-Qura calendar by default; the committee can override the
/// first day (UK moon sighting can differ by a day) through `RemoteConfig.ramadanStart` ("yyyy-MM-dd").
enum Ramadan {
    static let imsakMinutesBeforeFajr = 10
    static let lookaheadDays = 30
    static let length = 30

    private static var london: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    private static var hijri: Calendar = {
        var c = Calendar(identifier: .islamicUmmAlQura)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    static func start(override: String?, around now: Date) -> Date? {
        if let override, let d = parse(override) { return d }
        // First day of the Hijri month 9 on or after (now - 31 days).
        let probe = london.date(byAdding: .day, value: -31, to: now)!
        for offset in 0...400 {
            let d = london.date(byAdding: .day, value: offset, to: probe)!
            let c = hijri.dateComponents([.month, .day], from: d)
            if c.month == 9 && c.day == 1 { return london.startOfDay(for: d) }
        }
        return nil
    }

    static func state(now: Date, override: String?) -> RamadanState {
        guard let start = start(override: override, around: now) else { return .none }
        let today = london.startOfDay(for: now)
        let days = london.dateComponents([.day], from: start, to: today).day ?? 0
        if days < 0 { return -days <= lookaheadDays ? .before(daysUntil: -days) : .none }
        if days < length { return .during(day: days + 1) }
        return .none
    }

    static func isDuring(_ date: Date, override: String?) -> Bool {
        if case .during = state(now: date, override: override) { return true }
        return false
    }

    static func hijriString(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = hijri
        f.locale = Locale(identifier: "en_GB")
        f.timeZone = TimeZone(identifier: "Europe/London")
        f.dateFormat = "d MMMM y G"
        return f.string(from: date)
    }

    private static func parse(_ s: String) -> Date? {
        let f = DateFormatter()
        f.calendar = london
        f.timeZone = london.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
}
