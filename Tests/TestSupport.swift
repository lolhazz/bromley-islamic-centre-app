import Foundation

enum TestClock {
    static let london: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        london.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    /// "6:05 am" style, London time.
    static func hm(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.timeZone = london.timeZone
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
}
