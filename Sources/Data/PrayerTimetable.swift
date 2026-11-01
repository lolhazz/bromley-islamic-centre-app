import Foundation

/// How the jama'ah (iqamah) time is set for one prayer: a gap after the adhan, or a fixed clock time.
/// Set by the committee in the editor. The fixed time wins if both are present.
struct IqamahRule: Codable, Equatable {
    var afterMinutes: Int?
    /// 24-hour "HH:mm", London time.
    var time: String?

    /// The iqamah for an adhan on `day`, or `fallback` when the rule is unusable (out of range, or a fixed
    /// time that is not after the adhan).
    func resolve(adhan: Date, day: DateComponents, fallback: Date) -> Date {
        if let time, let (h, m) = Self.hourMinute(time) {
            var c = DateComponents(year: day.year, month: day.month, day: day.day, hour: h, minute: m)
            c.timeZone = PrayerCalculator.london.timeZone
            if let d = PrayerCalculator.london.date(from: c), d > adhan { return d }
            return fallback
        }
        if let afterMinutes, (0...180).contains(afterMinutes) {
            return adhan.addingTimeInterval(Double(afterMinutes) * 60)
        }
        return fallback
    }

    static func hourMinute(_ text: String) -> (Int, Int)? {
        let p = text.split(separator: ":")
        guard p.count == 2, p[0].count == 2, p[1].count == 2,
              let h = Int(p[0]), let m = Int(p[1]), (0..<24).contains(h), (0..<60).contains(m) else { return nil }
        return (h, m)
    }
}

/// One year of adhan times from the London Unified Prayer Timetable, as served by the editor's `/api/times`.
struct PrayerTimetable: Codable, Equatable {
    struct Day: Codable, Equatable {
        let fajr, sunrise, dhuhr, asr, maghrib, isha: String
    }
    let year: Int
    /// Keyed "yyyy-MM-dd".
    let days: [String: Day]

    static func key(_ c: DateComponents) -> String {
        String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// The day's schedule with the usual iqamah gaps, or nil if the timetable lacks the day or has a bad time.
    func schedule(for day: Date) -> DaySchedule? {
        let cal = PrayerCalculator.london
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        guard comps.year == year, let d = days[Self.key(comps)] else { return nil }
        func at(_ text: String) -> Date? {
            guard let (h, m) = IqamahRule.hourMinute(text) else { return nil }
            var c = comps; c.hour = h; c.minute = m
            return cal.date(from: c)
        }
        guard let fajr = at(d.fajr), let sunrise = at(d.sunrise), let dhuhr = at(d.dhuhr),
              let asr = at(d.asr), let maghrib = at(d.maghrib), let isha = at(d.isha) else { return nil }
        return DaySchedule(
            date: cal.date(from: comps)!,
            sunrise: sunrise,
            entries: zip(Prayer.allCases, [fajr, dhuhr, asr, maghrib, isha]).map { PrayerEntry(prayer: $0, adhan: $1) }
        )
    }
}
