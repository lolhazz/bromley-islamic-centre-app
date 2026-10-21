import WidgetKit
import SwiftUI
#if canImport(BromleyIslamicCentre)
@testable import BromleyIslamicCentre   // when compiled into the unit-test target
#endif

enum PrayerPhase { case upcoming, iqamah, inProgress }

struct PrayerEntryData: TimelineEntry {
    let date: Date
    /// The five prayers for the day the "current" prayer belongs to.
    let entries: [PrayerEntry]
    let sunrise: Date
    let current: PrayerEntry
    let phase: PrayerPhase
    /// What the countdown runs to: adhan, or iqamah once adhan has passed. nil while jama'ah is in progress.
    let countdownTo: Date?
    /// Bounds of the current stretch of time, for the lock-screen progress ring.
    let periodStart: Date
    let periodEnd: Date
    /// Day of Ramadan (calendar-based) when it is Ramadan, with that day's imsak and iftar times.
    let ramadanDay: Int?
    let imsak: Date
    let iftar: Date
    let hijri: String

    static func make(at now: Date) -> PrayerEntryData {
        let today = PrayerCalculator.schedule(for: now)
        let yesterday = PrayerCalculator.schedule(for: Calendar.current.date(byAdding: .day, value: -1, to: now)!)
        let tomorrow = PrayerCalculator.schedule(for: PrayerCalculator.tomorrow(after: today.date))
        let (state, entry) = NextPrayer.resolve(now: now, schedule: today, tomorrow: tomorrow)
        let onTomorrow = entry.adhan >= tomorrow.date
        let day = onTomorrow ? tomorrow : today

        let all = (yesterday.entries + today.entries + tomorrow.entries)
        let previousAdhan = all.last(where: { $0.adhan <= now && $0.prayer != entry.prayer || $0.adhan < entry.adhan && $0.adhan <= now })?.adhan
            ?? entry.adhan.addingTimeInterval(-4 * 3600)

        let phase: PrayerPhase, target: Date?, start: Date, end: Date
        switch state {
        case .upcoming(let e, _): phase = .upcoming; target = e.adhan; start = previousAdhan; end = e.adhan
        case .iqamahSoon(let e, _): phase = .iqamah; target = e.iqamah; start = e.adhan; end = e.iqamah
        case .inProgress(let e): phase = .inProgress; target = nil; start = e.iqamah; end = e.iqamah.addingTimeInterval(15 * 60)
        }

        var ramadanDay: Int?
        if case .during(let d) = Ramadan.state(now: now, override: nil) { ramadanDay = d }
        let imsak = day.entries[0].adhan.addingTimeInterval(-Double(Ramadan.imsakMinutesBeforeFajr) * 60)

        return PrayerEntryData(date: now, entries: day.entries, sunrise: day.sunrise, current: entry, phase: phase,
                               countdownTo: target, periodStart: start, periodEnd: max(end, start.addingTimeInterval(60)),
                               ramadanDay: ramadanDay, imsak: imsak, iftar: day.entries[3].adhan,
                               hijri: Ramadan.hijriString(for: now))
    }
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntryData { .make(at: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PrayerEntryData) -> Void) { completion(.make(at: .now)) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntryData>) -> Void) {
        var dates: Set<Date> = [.now]
        for offset in 0..<2 {
            let day = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
            for e in PrayerCalculator.schedule(for: day).entries {
                for d in [e.adhan, e.iqamah, e.iqamah.addingTimeInterval(15 * 60)] where d > .now { dates.insert(d) }
            }
        }
        completion(Timeline(entries: dates.sorted().prefix(30).map { .make(at: $0) }, policy: .atEnd))
    }
}
