import SwiftUI

struct TodayView: View {
    @State private var showAlerts = false
    @EnvironmentObject private var config: ConfigStore
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            content(now: ctx.date)
        }
    }

    private func content(now: Date) -> some View {
        let today = PrayerCalculator.schedule(for: now)
        let tomorrow = PrayerCalculator.schedule(for: PrayerCalculator.tomorrow(after: today.date))
        let (state, current) = NextPrayer.resolve(now: now, schedule: today, tomorrow: tomorrow)

        return ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(now: now)
                    nextCard(state: state)
                    venueBanner
                    ramadanCard(today: today, now: now)
                    prayerGrid(entries: today.entries, highlight: current.adhan < tomorrow.date ? current : nil)
                    sunriseRow(today.sunrise)
                    jumuah
                    openingHours
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func header(now: Date) -> some View {
        HStack(spacing: 14) {
            Image("Logo")
                .resizable().scaledToFit()
                .frame(width: 52, height: 52)
                .padding(4)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: "Today in Bromley")
                Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB"))))
                    .font(.display(22, weight: .medium))
                    .foregroundStyle(.white)
                Text(Ramadan.hijriString(for: now))
                    .font(.body(12)).foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Button { showAlerts = true } label: {
                Image(systemName: "bell.badge").font(.title3).foregroundStyle(Theme.gold)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Prayer alerts")
        }
        .sheet(isPresented: $showAlerts) { AlertsView() }
    }

    @ViewBuilder
    private func ramadanCard(today: DaySchedule, now: Date) -> some View {
        let state = Ramadan.state(now: now, override: config.ramadanStart)
        if case .none = state { EmptyView() } else {
            let fajr = today.entries[0].adhan, maghrib = today.entries[3].adhan
            let imsak = fajr.addingTimeInterval(-Double(Ramadan.imsakMinutesBeforeFajr) * 60)
            VStack(alignment: .leading, spacing: 12) {
                switch state {
                case let .before(d):
                    Eyebrow(text: "Ramadan is coming")
                    Text("About \(d) day\(d == 1 ? "" : "s") to go")
                        .font(.display(26, weight: .semibold)).foregroundStyle(.white)
                case let .during(day):
                    Eyebrow(text: "Ramadan · day \(day)")
                    HStack {
                        ramadanTime("Imsak", imsak)
                        ramadanTime("Suhoor ends · Fajr", fajr)
                        ramadanTime("Iftar · Maghrib", maghrib)
                    }
                case .none: EmptyView()
                }
                Text(config.ramadanNote ?? "Taraweeh and community iftar venues and timings are announced before the month begins.")
                    .font(.body(13)).foregroundStyle(.white.opacity(0.75))
                Text("Start of Ramadan follows the moon and may differ by a day.")
                    .font(.body(11)).foregroundStyle(.white.opacity(0.5))
            }
            .card(stroke: Theme.gold.opacity(0.45))
        }
    }

    private func ramadanTime(_ label: String, _ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(.body(9, weight: .bold)).tracking(0.8).foregroundStyle(Theme.gold)
            Text(TimeFormat.clock(date)).font(.body(17, weight: .bold)).foregroundStyle(.white).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var venueBanner: some View {
        Label { Text(config.venueBanner).font(.body(13)).foregroundStyle(.white.opacity(0.85)) }
            icon: { Image(systemName: "mappin.and.ellipse").foregroundStyle(Theme.gold) }
            .card(radius: 16, stroke: Theme.gold.opacity(0.3))
    }

    private func nextCard(state: NextPrayer) -> some View {
        let (title, detail, entry): (String, String, PrayerEntry) = {
            switch state {
            case let .upcoming(e, s): ("Next: \(e.prayer.rawValue)", "Adhan in \(TimeFormat.countdown(s))", e)
            case let .iqamahSoon(e, s): (e.prayer.rawValue, "Jama’ah in \(TimeFormat.countdown(s))", e)
            case let .inProgress(e): (e.prayer.rawValue, "Jama’ah in progress", e)
            }
        }()
        return VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: title)
            Text(detail)
                .font(.display(34, weight: .semibold))
                .foregroundStyle(.white)
            Text("Adhan \(TimeFormat.clock(entry.adhan))  ·  Iqamah \(TimeFormat.clock(entry.iqamah))")
                .font(.body(15))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.gold.opacity(0.35)))
        .accessibilityElement(children: .combine)
    }

    private func prayerGrid(entries: [PrayerEntry], highlight: PrayerEntry?) -> some View {
        VStack(spacing: 0) {
            ForEach(entries) { e in
                let active = e.prayer == highlight?.prayer
                HStack {
                    Text(e.prayer.rawValue.uppercased())
                        .font(.body(13, weight: .bold)).tracking(1.4)
                        .foregroundStyle(active ? Theme.gold : .white.opacity(0.85))
                        .frame(width: 90, alignment: .leading)
                    Spacer()
                    timeColumn("Adhan", e.adhan, .white)
                    timeColumn("Iqamah", e.iqamah, Theme.gold)
                }
                .padding(.vertical, 14).padding(.horizontal, 16)
                .background(active ? Color.white.opacity(0.1) : .clear)
                if e.prayer != .isha { Divider().overlay(.white.opacity(0.12)) }
            }
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 24))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15)))
    }

    private func timeColumn(_ label: String, _ date: Date, _ color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label.uppercased()).font(.body(10, weight: .medium)).tracking(1).foregroundStyle(color.opacity(0.7))
            Text(TimeFormat.clock(date)).font(.body(18, weight: .bold)).foregroundStyle(color).monospacedDigit()
        }
        .frame(width: 92, alignment: .trailing)
    }

    private func sunriseRow(_ sunrise: Date) -> some View {
        HStack {
            Image(systemName: "sunrise").foregroundStyle(Theme.gold)
            Text("Sunrise").font(.body(15)).foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(TimeFormat.clock(sunrise)).font(.body(16, weight: .bold)).foregroundStyle(.white).monospacedDigit()
        }
        .padding(.horizontal, 4)
    }

    private var jumuah: some View {
        let isFriday = Calendar.current.component(.weekday, from: .now) == 6
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: isFriday ? "Today · Jumu’ah" : "Friday · Jumu’ah")
            HStack(spacing: 12) {
                ForEach(config.jumuah) { jumuahCard($0) }
            }
        }
    }

    private func jumuahCard(_ slot: JumuahSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.label).font(.display(20, weight: .medium)).foregroundStyle(.white)
            row("Khutbah", slot.khutbah)
            row("Jama’ah", slot.jamaah)
            if let v = slot.venue, !v.isEmpty { Text(v).font(.body(12)).foregroundStyle(.white.opacity(0.7)) }
            if let n = slot.note, !n.isEmpty { Text(n).font(.body(12)).italic().foregroundStyle(Theme.gold) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.35)))
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.body(13)).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(v).font(.body(14, weight: .bold)).foregroundStyle(.white).monospacedDigit()
        }
    }

    private var openingHours: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Masjid opening hours")
            Text("Opens 15 minutes before each congregational prayer and closes 30 minutes after it has finished. We currently meet in temporary community spaces; check each event for its venue.")
                .font(.body(14)).foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) { Rectangle().fill(Theme.gold).frame(width: 3) }
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
