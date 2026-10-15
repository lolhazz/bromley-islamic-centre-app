import WidgetKit
import SwiftUI

private let teal = Color(red: 0.000, green: 0.282, blue: 0.275)
private let tealDeep = Color(red: 0.008, green: 0.133, blue: 0.157)
private let gold = Color(red: 0.851, green: 0.647, blue: 0.227)

struct PrayerEntryData: TimelineEntry {
    let date: Date
    let entries: [PrayerEntry]
    let current: PrayerEntry
    /// Moment the countdown runs to (adhan, or iqamah once adhan has passed). nil while jama'ah is in progress.
    let countdownTo: Date?
    let phase: String
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntryData { make(at: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PrayerEntryData) -> Void) { completion(make(at: .now)) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntryData>) -> Void) {
        var dates: Set<Date> = [.now]
        for offset in 0..<2 {
            let day = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
            for e in PrayerCalculator.schedule(for: day).entries {
                for d in [e.adhan, e.iqamah, e.iqamah.addingTimeInterval(15 * 60)] where d > .now { dates.insert(d) }
            }
        }
        let sorted = dates.sorted().prefix(30)
        completion(Timeline(entries: sorted.map { make(at: $0) }, policy: .atEnd))
    }

    private func make(at now: Date) -> PrayerEntryData {
        let today = PrayerCalculator.schedule(for: now)
        let tomorrow = PrayerCalculator.schedule(for: PrayerCalculator.tomorrow(after: today.date))
        let (state, entry) = NextPrayer.resolve(now: now, schedule: today, tomorrow: tomorrow)
        let list = entry.adhan < tomorrow.date ? today.entries : tomorrow.entries
        switch state {
        case .upcoming(let e, _): return .init(date: now, entries: list, current: e, countdownTo: e.adhan, phase: "Adhan")
        case .iqamahSoon(let e, _): return .init(date: now, entries: list, current: e, countdownTo: e.iqamah, phase: "Jama’ah")
        case .inProgress(let e): return .init(date: now, entries: list, current: e, countdownTo: nil, phase: "Jama’ah in progress")
        }
    }
}

struct PrayerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntryData

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.current.prayer.rawValue) \(TimeFormat.clock(entry.current.adhan))")
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(entry.current.prayer.rawValue.prefix(3).uppercased()).font(.caption2.bold())
                Text(TimeFormat.clock(entry.current.adhan).replacingOccurrences(of: " ", with: "")).font(.caption)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.current.prayer.rawValue).font(.headline)
                Text("Adhan \(TimeFormat.clock(entry.current.adhan))")
                Text("Iqamah \(TimeFormat.clock(entry.current.iqamah))")
            }.frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            HStack(alignment: .top, spacing: 14) {
                header.frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 4) {
                    ForEach(entry.entries) { e in
                        HStack {
                            Text(e.prayer.rawValue).font(.caption.weight(e.prayer == entry.current.prayer ? .bold : .regular))
                                .foregroundStyle(e.prayer == entry.current.prayer ? gold : .white)
                            Spacer()
                            Text(TimeFormat.clock(e.adhan)).font(.caption.monospacedDigit()).foregroundStyle(.white)
                        }
                    }
                }.frame(maxWidth: .infinity)
            }
        default:
            header
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.countdownTo == nil ? entry.current.prayer.rawValue.uppercased() : "NEXT · \(entry.current.prayer.rawValue.uppercased())")
                .font(.caption2.bold()).tracking(1.2).foregroundStyle(gold)
            if let t = entry.countdownTo {
                Text(t, style: .timer).font(.system(size: 30, weight: .semibold, design: .serif)).monospacedDigit().foregroundStyle(.white)
                Text("until \(entry.phase.lowercased())").font(.caption2).foregroundStyle(.white.opacity(0.7))
            } else {
                Text("Jama’ah in progress").font(.system(size: 20, weight: .semibold, design: .serif)).foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            Text("Adhan \(TimeFormat.clock(entry.current.adhan))").font(.caption).foregroundStyle(.white)
            Text("Iqamah \(TimeFormat.clock(entry.current.iqamah))").font(.caption).foregroundStyle(gold)
        }
    }
}

struct PrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BromleyPrayerWidget", provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [teal, tealDeep], startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Next prayer")
        .description("Countdown to the next adhan or jama’ah at Bromley Islamic Centre.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct BromleyWidgetBundle: WidgetBundle {
    var body: some Widget { PrayerWidget() }
}
