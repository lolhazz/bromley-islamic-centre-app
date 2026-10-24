import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var config: ConfigStore
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { ctx in
            content(now: ctx.date)
        }
    }

    private func content(now: Date) -> some View {
        let today = PrayerCalculator.schedule(for: now)
        let tomorrow = PrayerCalculator.schedule(for: PrayerCalculator.tomorrow(after: today.date))
        let (state, current) = NextPrayer.resolve(now: now, schedule: today, tomorrow: tomorrow)
        let onTomorrow = current.adhan >= tomorrow.date
        let highlight = onTomorrow ? nil : current

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(now: now)
                    hero(state: state, tomorrow: onTomorrow)
                    Text(config.venueBanner)
                        .font(.body(14, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary)
                    ramadanCard(today: today, now: now)
                    prayerList(today: today, highlight: highlight)
                    jumuah(now: now)
                    openingHours
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(ScreenBackground())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        let logo = Image("Logo")
            .renderingMode(.template)
            .resizable().scaledToFit()
            .foregroundStyle(Theme.textPrimary)
            .frame(width: 52, height: 52)
            .accessibilityLabel("Bromley Islamic Centre")
        let bell = NavigationLink { AlertsView() } label: {
            Image(systemName: "bell").font(.title3).foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Prayer alerts")
        let dates = VStack(alignment: .leading, spacing: 2) {
            Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB"))))
                .font(.display(28, weight: .semibold, relativeTo: .title))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(Ramadan.hijriString(for: now))
                .font(.body(14, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
        }
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { logo; Spacer(); bell }
                    dates
                }
            } else {
                HStack(spacing: 14) { logo; dates; Spacer(minLength: 0); bell }
            }
        }
    }

    // MARK: Hero (name first, then the time left)

    private func hero(state: NextPrayer, tomorrow: Bool) -> some View {
        let model: (status: String, entry: PrayerEntry, spoken: String) = {
            let day = tomorrow ? "Tomorrow, " : ""
            switch state {
            case let .upcoming(e, s):
                return ("\(day)adhan in \(TimeFormat.countdown(s))", e, "Next prayer \(e.prayer.rawValue). \(tomorrow ? "Tomorrow, " : "")Adhan in \(TimeFormat.spoken(s)).")
            case let .iqamahSoon(e, s):
                return ("Jama’ah in \(TimeFormat.countdown(s))", e, "\(e.prayer.rawValue). Jama’ah in \(TimeFormat.spoken(s)).")
            case let .inProgress(e):
                return ("Jama’ah in progress", e, "\(e.prayer.rawValue). Jama’ah in progress.")
            }
        }()
        return HeroCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.entry.prayer.rawValue)
                    .font(.display(56, weight: .semibold, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.onHero)
                Text(model.status)
                    .font(.body(20, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.onHeroAccent)
                    .padding(.bottom, 12)
                heroTime("Adhan", model.entry.adhan, Theme.onHero)
                heroTime("Iqamah", model.entry.iqamah, Theme.onHeroAccent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.spoken)
        .accessibilityValue("Adhan \(TimeFormat.clock(model.entry.adhan)). Iqamah \(TimeFormat.clock(model.entry.iqamah)).")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func heroTime(_ label: String, _ date: Date, _ color: Color) -> some View {
        HStack {
            Text(label).font(.body(16, relativeTo: .callout)).foregroundStyle(Theme.onHeroSecondary)
            Spacer(minLength: 12)
            Text(TimeFormat.clock(date)).font(.body(20, weight: .bold, relativeTo: .title3)).monospacedDigit().foregroundStyle(color)
        }
        .padding(.vertical, 3)
        .frame(maxWidth: 320)
    }

    // MARK: Ramadan

    @ViewBuilder
    private func ramadanCard(today: DaySchedule, now: Date) -> some View {
        let state = Ramadan.state(now: now, override: config.ramadanStart)
        if case .none = state { EmptyView() } else {
            let fajr = today.entries[0].adhan, maghrib = today.entries[3].adhan
            let imsak = fajr.addingTimeInterval(-Double(Ramadan.imsakMinutesBeforeFajr) * 60)
            VStack(alignment: .leading, spacing: 12) {
                switch state {
                case let .before(d):
                    SectionTitle("Ramadan is coming")
                    Text("About \(d) day\(d == 1 ? "" : "s") to go").font(.body(16, weight: .medium)).foregroundStyle(Theme.textPrimary)
                case let .during(day):
                    SectionTitle("Ramadan, day \(day)")
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top) { ramadanTime("Imsak", imsak); ramadanTime("Suhoor ends", fajr); ramadanTime("Iftar", maghrib) }
                        VStack(alignment: .leading, spacing: 10) { ramadanTime("Imsak", imsak); ramadanTime("Suhoor ends", fajr); ramadanTime("Iftar", maghrib) }
                    }
                case .none: EmptyView()
                }
                Text(config.ramadanNote ?? "Taraweeh and community iftar venues and timings are announced before the month begins.")
                    .font(.body(14, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary)
                Text("The start of Ramadan follows the moon and may differ by a day.")
                    .font(.body(12, relativeTo: .caption)).foregroundStyle(Theme.textSecondary)
            }
            .surfaceCard()
        }
    }

    private func ramadanTime(_ label: String, _ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.body(13, weight: .medium, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
            Text(TimeFormat.clock(date)).font(.body(20, weight: .bold, relativeTo: .title3)).monospacedDigit().foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(TimeFormat.clock(date))")
    }

    // MARK: Prayer list

    private func columnHeader(_ a: String, _ b: String) -> some View {
        HStack {
            Spacer()
            Text(a).frame(width: 92, alignment: .trailing)
            Text(b).frame(width: 92, alignment: .trailing)
        }
        .font(.body(13, weight: .medium, relativeTo: .caption))
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 16)
        .accessibilityHidden(true)
    }

    private func listContainer<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0) { content() }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.stroke))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func prayerList(today: DaySchedule, highlight: PrayerEntry?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !typeSize.isAccessibilitySize { columnHeader("Adhan", "Iqamah") }
            listContainer {
                ForEach(Array(today.entries.enumerated()), id: \.element.id) { idx, e in
                    prayerRow(e, active: e.prayer == highlight?.prayer)
                    if idx == 0 { sunriseRow(today.sunrise) }
                    if idx < today.entries.count - 1 { Hairline().padding(.horizontal, 16) }
                }
            }
        }
    }

    private func prayerRow(_ e: PrayerEntry, active: Bool) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(e.prayer.rawValue).font(.body(20, weight: .bold, relativeTo: .title3))
                    Text("Adhan \(TimeFormat.clock(e.adhan))").font(.body(18, relativeTo: .body)).monospacedDigit()
                    Text("Iqamah \(TimeFormat.clock(e.iqamah))").font(.body(18, weight: .bold, relativeTo: .body)).monospacedDigit().foregroundStyle(Theme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    Text(e.prayer.rawValue).font(.body(18, weight: active ? .bold : .medium, relativeTo: .headline))
                    Spacer()
                    Text(TimeFormat.clock(e.adhan)).font(.body(18, weight: active ? .bold : .medium, relativeTo: .headline)).monospacedDigit()
                        .frame(width: 92, alignment: .trailing)
                    Text(TimeFormat.clock(e.iqamah)).font(.body(18, weight: .bold, relativeTo: .headline)).monospacedDigit()
                        .foregroundStyle(Theme.accent).frame(width: 92, alignment: .trailing)
                }
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.vertical, 16).padding(.horizontal, 16)
        .background(active ? Theme.accent.opacity(0.12) : .clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(e.prayer.rawValue)
        .accessibilityValue("Adhan \(TimeFormat.clock(e.adhan)). Iqamah \(TimeFormat.clock(e.iqamah)).")
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func sunriseRow(_ sunrise: Date) -> some View {
        VStack(spacing: 0) {
            Hairline().padding(.horizontal, 16)
            HStack {
                Text("Sunrise").font(.body(15, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(TimeFormat.clock(sunrise)).font(.body(15, weight: .medium, relativeTo: .subheadline)).monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 12).padding(.horizontal, 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sunrise \(TimeFormat.clock(sunrise))")
        }
    }

    // MARK: Jumu'ah (same list style as the prayers)

    private func jumuah(now: Date) -> some View {
        let isFriday = Calendar.current.component(.weekday, from: now) == 6
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(isFriday ? "Jumu’ah today" : "Jumu’ah on Friday")
            if !typeSize.isAccessibilitySize { columnHeader("Khutbah", "Jama’ah") }
            listContainer {
                ForEach(Array(config.jumuah.enumerated()), id: \.element.id) { idx, slot in
                    jumuahRow(slot)
                    if idx < config.jumuah.count - 1 { Hairline().padding(.horizontal, 16) }
                }
            }
        }
    }

    private func jumuahRow(_ slot: JumuahSlot) -> some View {
        let extras = [slot.venue, slot.note].compactMap { $0 }.filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: 4) {
            if typeSize.isAccessibilitySize {
                Text(slot.label).font(.body(20, weight: .bold, relativeTo: .title3))
                Text("Khutbah \(slot.khutbah)").font(.body(18)).monospacedDigit()
                Text("Jama’ah \(slot.jamaah)").font(.body(18, weight: .bold)).monospacedDigit().foregroundStyle(Theme.accent)
            } else {
                HStack {
                    Text(slot.label).font(.body(18, weight: .medium, relativeTo: .headline))
                    Spacer()
                    Text(slot.khutbah).font(.body(18, weight: .medium, relativeTo: .headline)).monospacedDigit()
                        .frame(width: 92, alignment: .trailing)
                    Text(slot.jamaah).font(.body(18, weight: .bold, relativeTo: .headline)).monospacedDigit()
                        .foregroundStyle(Theme.accent).frame(width: 92, alignment: .trailing)
                }
            }
            ForEach(extras, id: \.self) { Text($0).font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary) }
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.vertical, 16).padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(slot.label)
        .accessibilityValue("Khutbah \(slot.khutbah). Jama’ah \(slot.jamaah).\(extras.map { " \($0)." }.joined())")
    }

    // MARK: Footnote

    private var openingHours: some View {
        Text("The Masjid opens 15 minutes before each congregational prayer and closes 30 minutes after it has finished. Adhan times are calculated for Bromley; congregational times can differ, so please confirm the venue and jama’ah time before you travel.")
            .font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
    }
}
