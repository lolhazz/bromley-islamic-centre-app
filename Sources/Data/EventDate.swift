import Foundation

/// Reads the date out of the committee's free-text "when" field (for example "Fri 23 Oct 2026 · 1:15 pm") so the
/// app can say "In 2 days" and hide events that are over. Text it cannot read (for example "Sundays · 2:45 pm")
/// is treated as recurring: no countdown, never hidden.
enum EventDate {
    struct Parsed: Equatable {
        let date: Date
        let hasTime: Bool
    }

    private static let london: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        c.locale = Locale(identifier: "en_GB")
        return c
    }()

    private static let months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

    static func parse(_ when: String?) -> Parsed? {
        guard let when else { return nil }
        let text = when.lowercased()
        guard let d = text.firstMatch(of: /(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?,?\s+(\d{4})/),
              let day = Int(d.1), let year = Int(d.3),
              let month = months.firstIndex(of: String(d.2)).map({ $0 + 1 }),
              (1...31).contains(day)
        else { return nil }
        var comps = DateComponents(year: year, month: month, day: day, hour: 23, minute: 59)
        var hasTime = false
        if let t = text.firstMatch(of: /(\d{1,2})(?::(\d{2}))?\s*(am|pm)/), var h = Int(t.1), (1...12).contains(h) {
            if t.3 == "pm" && h != 12 { h += 12 }
            if t.3 == "am" && h == 12 { h = 0 }
            comps.hour = h
            comps.minute = t.2.flatMap { Int($0) } ?? 0
            hasTime = true
        }
        guard let date = london.date(from: comps), london.component(.day, from: date) == day else { return nil }
        return Parsed(date: date, hasTime: hasTime)
    }

    /// Over: its time has passed, or (with no time) its day has.
    static func isOver(_ when: String?, now: Date) -> Bool {
        guard let p = parse(when) else { return false }
        return p.date < now
    }

    /// "Today", "Tomorrow", "In 5 days", "In 3 weeks". nil when the text has no readable date or the event is over.
    static func countdown(_ when: String?, now: Date) -> String? {
        guard let p = parse(when), p.date >= now else { return nil }
        let days = london.dateComponents([.day], from: london.startOfDay(for: now), to: london.startOfDay(for: p.date)).day ?? 0
        switch days {
        case ..<1: return "Today"
        case 1: return "Tomorrow"
        case 2...13: return "In \(days) days"
        default:
            let weeks = days / 7
            return "In \(weeks) weeks"
        }
    }
}
