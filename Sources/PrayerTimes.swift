import Foundation

enum Prayer: String, CaseIterable, Identifiable {
    case fajr = "Fajr", dhuhr = "Dhuhr", asr = "Asr", maghrib = "Maghrib", isha = "Isha"
    var id: String { rawValue }

    /// Minutes after adhan that the jama'ah (iqamah) starts, per the centre's published rules.
    var iqamahOffset: Int {
        switch self {
        case .fajr: 40
        case .dhuhr: 46
        case .asr: 27
        case .maghrib: 5
        case .isha: 31
        }
    }
}

struct PrayerEntry: Identifiable {
    let prayer: Prayer
    let adhan: Date
    let iqamah: Date
    var id: String { prayer.id }

    /// `iqamah` defaults to the centre's usual gap after the adhan.
    init(prayer: Prayer, adhan: Date, iqamah: Date? = nil) {
        self.prayer = prayer
        self.adhan = adhan
        self.iqamah = iqamah ?? adhan.addingTimeInterval(Double(prayer.iqamahOffset) * 60)
    }
}

struct DaySchedule {
    let date: Date
    let sunrise: Date
    let entries: [PrayerEntry]
}

/// Astronomical prayer-time calculation for Bromley. This is the fallback: `PrayerSource` uses the London
/// Unified Prayer Timetable when the app has it, and falls back to these times (offline, or a year it lacks).
/// Angles/offsets were fitted against the centre's website (Fajr 15°, Isha 13.5°, standard Asr).
enum PrayerCalculator {
    static let latitude = 51.4060
    static let longitude = 0.0148
    static let fajrAngle = 15.0
    static let ishaAngle = 13.5
    static let asrAdjustMinutes = -2.0
    static let maghribAdjustMinutes = -2.0

    static let london: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }

    /// The day's times as the app should show them: timetable if available, otherwise calculated, with the
    /// committee's iqamah rules applied.
    static func schedule(for day: Date) -> DaySchedule { PrayerSource.schedule(for: day) }

    /// Pure astronomical calculation, with the usual iqamah gaps.
    static func calculate(for day: Date) -> DaySchedule {
        let comps = london.dateComponents([.year, .month, .day], from: day)
        let midnight = london.date(from: comps)!
        // Anchor on UTC midnight: the solar times are UT hours, and local midnight is wrong by an hour
        // on the two days a year when the clocks change (the day is 23 or 25 hours long).
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let utcMidnight = utc.date(from: comps)!

        // Julian day at 0h UT for that civil date
        let y = Double(comps.year!), m = Double(comps.month!), d = Double(comps.day!)
        let a = floor((14 - m) / 12), yy = y + 4800 - a, mm = m + 12 * a - 3
        let jd = d + floor((153 * mm + 2) / 5) + 365 * yy + floor(yy / 4) - floor(yy / 100) + floor(yy / 400) - 32045 - 0.5
        let n = jd - 2451545.0

        let g = rad((357.529 + 0.98560028 * n).truncatingRemainder(dividingBy: 360))
        let q = (280.459 + 0.98564736 * n).truncatingRemainder(dividingBy: 360)
        let lambda = rad((q + 1.915 * sin(g) + 0.020 * sin(2 * g)).truncatingRemainder(dividingBy: 360))
        let eps = rad(23.439 - 0.00000036 * n)
        let decl = asin(sin(eps) * sin(lambda))
        var ra = deg(atan2(cos(eps) * sin(lambda), cos(lambda))) / 15
        ra = ra.truncatingRemainder(dividingBy: 24); if ra < 0 { ra += 24 }
        var eqt = q / 15 - ra
        eqt = (eqt + 12).truncatingRemainder(dividingBy: 24); if eqt < 0 { eqt += 24 }; eqt -= 12

        let lat = rad(latitude)
        let noon = 12 - longitude / 15 - eqt          // UT hours
        func hourAngle(_ altitude: Double) -> Double {
            let c = (-sin(rad(altitude)) - sin(lat) * sin(decl)) / (cos(lat) * cos(decl))
            return deg(acos(min(1, max(-1, c)))) / 15
        }
        let asrAlt = -deg(atan(1 / (1 + tan(abs(lat - decl)))))
        let horizon = 0.833

        func date(_ utHours: Double, adjust minutes: Double = 0) -> Date {
            utcMidnight.addingTimeInterval(utHours * 3600 + minutes * 60)
        }

        let times: [(Prayer, Date)] = [
            (.fajr, date(noon - hourAngle(fajrAngle))),
            (.dhuhr, date(noon)),
            (.asr, date(noon + hourAngle(asrAlt), adjust: asrAdjustMinutes)),
            (.maghrib, date(noon + hourAngle(horizon), adjust: maghribAdjustMinutes)),
            (.isha, date(noon + hourAngle(ishaAngle))),
        ]
        return DaySchedule(
            date: midnight,
            sunrise: date(noon - hourAngle(horizon)),
            entries: times.map { PrayerEntry(prayer: $0.0, adhan: round($0.1)) }
        )
    }

    private static func round(_ d: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (d.timeIntervalSinceReferenceDate / 60).rounded() * 60)
    }

    static func tomorrow(after day: Date) -> Date {
        london.date(byAdding: .day, value: 1, to: day)!
    }
}

enum NextPrayer {
    case upcoming(PrayerEntry, in: TimeInterval)
    case iqamahSoon(PrayerEntry, in: TimeInterval)
    case inProgress(PrayerEntry)

    /// Mirrors the website: a prayer stays "next" until 15 min after its iqamah.
    static func resolve(now: Date, schedule: DaySchedule, tomorrow: DaySchedule) -> (NextPrayer, PrayerEntry) {
        for e in schedule.entries where e.iqamah.addingTimeInterval(15 * 60) > now {
            return (state(e, now), e)
        }
        let f = tomorrow.entries[0]
        return (.upcoming(f, in: f.adhan.timeIntervalSince(now)), f)
    }

    private static func state(_ e: PrayerEntry, _ now: Date) -> NextPrayer {
        if now < e.adhan { return .upcoming(e, in: e.adhan.timeIntervalSince(now)) }
        if now < e.iqamah { return .iqamahSoon(e, in: e.iqamah.timeIntervalSince(now)) }
        return .inProgress(e)
    }
}

enum TimeFormat {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.timeZone = TimeZone(identifier: "Europe/London")
        f.dateFormat = "h:mm a"
        return f
    }()

    static func clock(_ d: Date) -> String {
        formatter.string(from: d).replacingOccurrences(of: "AM", with: "am").replacingOccurrences(of: "PM", with: "pm")
    }

    /// "8 hours 8 minutes" for VoiceOver.
    static func spoken(_ s: TimeInterval) -> String {
        let m = max(0, Int((s / 60).rounded()))
        let h = m / 60, r = m % 60
        func unit(_ n: Int, _ w: String) -> String { "\(n) \(w)\(n == 1 ? "" : "s")" }
        if h == 0 { return unit(r, "minute") }
        return r == 0 ? unit(h, "hour") : "\(unit(h, "hour")) \(unit(r, "minute"))"
    }

    static func countdown(_ s: TimeInterval) -> String {
        let m = max(0, Int((s / 60).rounded()))
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
    }
}
