import SwiftUI

struct TodayView: View {
    @State private var showAlerts = false
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

    private var venueBanner: some View {
        Label { Text(Content.venueBanner).font(.body(13)).foregroundStyle(.white.opacity(0.85)) }
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
                jumuahCard("1st Jumu’ah", khutbah: "1:15 pm", jamaah: "1:30 pm")
                jumuahCard("2nd Jumu’ah", khutbah: "2:00 pm", jamaah: "2:15 pm")
            }
        }
    }

    private func jumuahCard(_ title: String, khutbah: String, jamaah: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.display(20, weight: .medium)).foregroundStyle(.white)
            row("Khutbah", khutbah)
            row("Jama’ah", jamaah)
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
