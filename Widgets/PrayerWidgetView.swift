import WidgetKit
import SwiftUI
#if canImport(BromleyIslamicCentre)
@testable import BromleyIslamicCentre   // when compiled into the unit-test target
#endif

/// Colours and fonts shared by the widgets. Mirrors the app's `Theme` (the extension has no asset catalog).
enum WidgetStyle {
    static let teal = Color(red: 0.016, green: 0.314, blue: 0.298)       // hero teal
    static let tealDeep = Color(red: 0.008, green: 0.176, blue: 0.188)
    static let gold = Color(red: 0.878, green: 0.690, blue: 0.290)
    static let text = Color.white
    static let secondary = Color(red: 0.78, green: 0.85, blue: 0.84)

    static func display(_ size: CGFloat) -> Font { .custom("Newsreader-SemiBold", size: size) }
    static func body(_ size: CGFloat, bold: Bool = false) -> Font { .custom(bold ? "DMSans-Bold" : "DMSans-Regular", size: size) }
}

/// Widget background: teal with star watermarks. Falls back to clear in tinted/accented/vibrant modes.
struct WidgetBackground: View {
    @Environment(\.widgetRenderingMode) private var mode
    var body: some View {
        if mode == .fullColor {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [WidgetStyle.teal, WidgetStyle.tealDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                EightPointStar().stroke(WidgetStyle.gold.opacity(0.20), lineWidth: 1.2)
                    .frame(width: 150, height: 150).offset(x: 62, y: 62)
                EightPointStar().stroke(WidgetStyle.gold.opacity(0.12), lineWidth: 1.2)
                    .frame(width: 100, height: 100).offset(x: 38, y: 38)
            }
        } else {
            Color.clear
        }
    }
}

/// Reads the widget family from the environment and renders the right layout.
struct PrayerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntryData
    var body: some View { PrayerWidgetView(entry: entry, family: family) }
}

/// Layouts per family. Takes the family as a parameter so it can be rendered in tests.
struct PrayerWidgetView: View {
    let entry: PrayerEntryData
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryInline: inline
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        case .systemLarge, .systemExtraLarge: large
        default: small
        }
    }

    // MARK: Pieces

    private var name: String { entry.current.prayer.rawValue }

    private var eyebrowText: String {
        entry.phase == .upcoming ? "NEXT · \(name.uppercased())" : name.uppercased()
    }

    private var captionText: String {
        switch entry.phase {
        case .upcoming: "until adhan"
        case .iqamah: "until jama’ah"
        case .inProgress: "jama’ah in progress"
        }
    }

    @ViewBuilder
    private func countdown(size: CGFloat) -> some View {
        if let t = entry.countdownTo {
            Text(t, style: .timer)
                .font(WidgetStyle.display(size)).monospacedDigit()
                .foregroundStyle(WidgetStyle.text)
                .minimumScaleFactor(0.6).lineLimit(1)
                .widgetAccentable()
        } else {
            Text("Now").font(WidgetStyle.display(size)).foregroundStyle(WidgetStyle.text).widgetAccentable()
        }
    }

    private func timeBlock(_ label: String, _ date: Date, gold: Bool, size: CGFloat = 16) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased()).font(WidgetStyle.body(9, bold: true)).tracking(1).foregroundStyle(WidgetStyle.secondary)
            Text(TimeFormat.clock(date)).font(WidgetStyle.body(size, bold: true)).monospacedDigit()
                .foregroundStyle(gold ? WidgetStyle.gold : WidgetStyle.text)
        }
    }

    private func timeLine(_ label: String, _ date: Date, gold: Bool) -> some View {
        HStack {
            Text(label).font(WidgetStyle.body(12)).foregroundStyle(WidgetStyle.secondary)
            Spacer(minLength: 6)
            Text(TimeFormat.clock(date)).font(WidgetStyle.body(14, bold: true)).monospacedDigit()
                .foregroundStyle(gold ? WidgetStyle.gold : WidgetStyle.text)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(eyebrowText).font(WidgetStyle.body(10, bold: true)).tracking(1.3).foregroundStyle(WidgetStyle.gold)
            countdown(size: 32)
            Text(captionText).font(WidgetStyle.body(12)).foregroundStyle(WidgetStyle.secondary)
            Spacer(minLength: 4)
            timeLine("Adhan", entry.current.adhan, gold: false)
            timeLine("Iqamah", entry.current.iqamah, gold: true)
        }
    }

    private func listRow(_ e: PrayerEntry, iqamah: Bool) -> some View {
        let active = e.prayer == entry.current.prayer
        return HStack(spacing: 6) {
            Text(e.prayer.rawValue).font(WidgetStyle.body(iqamah ? 15 : 13, bold: active))
                .foregroundStyle(active ? WidgetStyle.gold : WidgetStyle.text)
            Spacer(minLength: 4)
            Text(TimeFormat.clock(e.adhan)).font(WidgetStyle.body(iqamah ? 15 : 13, bold: active)).monospacedDigit()
                .foregroundStyle(WidgetStyle.text)
                .frame(width: iqamah ? 78 : nil, alignment: .trailing)
            if iqamah {
                Text(TimeFormat.clock(e.iqamah)).font(WidgetStyle.body(15, bold: true)).monospacedDigit()
                    .foregroundStyle(WidgetStyle.gold).frame(width: 78, alignment: .trailing)
            }
        }
    }

    // MARK: Home screen, notification centre, StandBy

    private var small: some View { hero }

    private var medium: some View {
        HStack(alignment: .top, spacing: 16) {
            hero.frame(maxWidth: .infinity, alignment: .leading)
            Rectangle().fill(WidgetStyle.secondary.opacity(0.3)).frame(width: 1)
            VStack(spacing: 6) {
                ForEach(entry.entries) { listRow($0, iqamah: false) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("BROMLEY ISLAMIC CENTRE").font(WidgetStyle.body(10, bold: true)).tracking(1.3).foregroundStyle(WidgetStyle.gold)
                Text(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB"))))
                    .font(WidgetStyle.display(20)).foregroundStyle(WidgetStyle.text)
                Text(entry.hijri).font(WidgetStyle.body(11)).foregroundStyle(WidgetStyle.secondary)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(eyebrowText).font(WidgetStyle.body(10, bold: true)).tracking(1.3).foregroundStyle(WidgetStyle.gold)
                countdown(size: 40)
                Text(captionText).font(WidgetStyle.body(12)).foregroundStyle(WidgetStyle.secondary)
            }
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("ADHAN").frame(width: 78, alignment: .trailing)
                    Text("IQAMAH").frame(width: 78, alignment: .trailing)
                }
                .font(WidgetStyle.body(9, bold: true)).tracking(1).foregroundStyle(WidgetStyle.secondary)
                VStack(spacing: 7) {
                    ForEach(Array(entry.entries.enumerated()), id: \.element.id) { i, e in
                        listRow(e, iqamah: true)
                        if i == 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "sunrise").font(.system(size: 11)).foregroundStyle(WidgetStyle.gold)
                                Text("Sunrise").font(WidgetStyle.body(12)).foregroundStyle(WidgetStyle.secondary)
                                Spacer()
                                Text(TimeFormat.clock(entry.sunrise)).font(WidgetStyle.body(12)).monospacedDigit()
                                    .foregroundStyle(WidgetStyle.secondary).frame(width: 78, alignment: .trailing)
                                Spacer().frame(width: 78)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
            if let day = entry.ramadanDay {
                Rectangle().fill(WidgetStyle.secondary.opacity(0.3)).frame(height: 1)
                HStack {
                    Text("RAMADAN · DAY \(day)").font(WidgetStyle.body(9, bold: true)).tracking(1).foregroundStyle(WidgetStyle.gold)
                    Spacer()
                    Text("Imsak \(TimeFormat.clock(entry.imsak))").font(WidgetStyle.body(12)).foregroundStyle(WidgetStyle.text)
                    Text("Iftar \(TimeFormat.clock(entry.iftar))").font(WidgetStyle.body(12, bold: true)).foregroundStyle(WidgetStyle.gold)
                }
            }
        }
    }

    // MARK: Lock screen

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill").font(.caption2)
                Text(entry.phase == .upcoming ? "Next · \(name)" : name).font(.headline)
            }
            .widgetAccentable()
            if let t = entry.countdownTo {
                Text(t, style: .timer).font(.title3.weight(.semibold)).monospacedDigit()
            } else {
                Text("Jama’ah now").font(.title3.weight(.semibold))
            }
            Text("Adhan \(shortClock(entry.current.adhan))  ·  Iqamah \(shortClock(entry.current.iqamah))")
                .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var circular: some View {
        ProgressView(timerInterval: entry.periodStart...entry.periodEnd, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: 0) {
                Text(String(name.prefix(3)).uppercased()).font(.system(size: 11, weight: .bold))
                Text(shortClock(entry.countdownTo ?? entry.current.iqamah)).font(.system(size: 11)).monospacedDigit()
            }
        }
        .progressViewStyle(.circular)
        .widgetAccentable()
    }

    private var inline: some View {
        Label("\(name) \(TimeFormat.clock(entry.current.adhan))", systemImage: "moon.stars")
    }

    private func shortClock(_ d: Date) -> String {
        TimeFormat.clock(d).replacingOccurrences(of: " am", with: "").replacingOccurrences(of: " pm", with: "")
    }
}
