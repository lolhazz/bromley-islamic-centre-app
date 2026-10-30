import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var config: ConfigStore

    /// Events that are not over, soonest dated one first.
    private func upcoming(now: Date) -> [EventItem] { config.events.filter { !EventDate.isOver($0.when, now: now) } }

    /// The next dated event, or failing that the first recurring one with a "when".
    private func featured(now: Date) -> EventItem? {
        let live = upcoming(now: now)
        return live.filter { EventDate.parse($0.when) != nil }.min { EventDate.parse($0.when)!.date < EventDate.parse($1.when)!.date }
            ?? live.first { $0.when != nil }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { ctx in content(now: DebugRoute.now(ctx.date)) }
    }

    private func content(now: Date) -> some View {
        let featured = featured(now: now)
        let others = upcoming(now: now).filter { $0.id != featured?.id }
        return NavigationStack {
            Screen {
                PageTitle(title: "What’s on")
                if let featured { featuredCard(featured, now: now) }
                announcements
                comingUp(others)
                FeedStatus(config: config)
                RowList {
                    ExternalRow(title: "Join the WhatsApp community", url: Site.whatsapp, subtitle: "Event, prayer and venue announcements")
                    ExternalRow(title: "Khutbahs and talks", url: Site.page("/videos"), subtitle: "Video library and live Jumu’ah")
                }
            }
            .refreshable { await config.refresh() }
        }
    }

    private func featuredCard(_ e: EventItem, now: Date) -> some View {
        let countdown = EventDate.countdown(e.when, now: now)
        return HeroCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(e.title).font(.display(32, weight: .semibold, relativeTo: .title)).foregroundStyle(Theme.onHero)
                    .lineLimit(4).minimumScaleFactor(0.55)   // shrink rather than break a long name mid-word
                if let countdown {
                    Text(countdown).font(.body(20, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.onHeroAccent)
                }
                if let w = e.when {
                    Text("\(e.tag) · \(w)").font(.body(16, weight: .medium, relativeTo: .callout))
                        .foregroundStyle(countdown == nil ? Theme.onHeroAccent : Theme.onHeroSecondary)
                }
                Text(e.detail).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.onHeroSecondary)
                    .padding(.top, 2)
                if let n = e.note { Text(n).font(.body(14, relativeTo: .footnote)).foregroundStyle(Theme.onHeroSecondary) }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var announcements: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Announcements")
            if config.announcements.isEmpty {
                EmptyNote(text: "No announcements right now. Join the WhatsApp community below to hear first.")
            } else {
                RowList {
                    ForEach(config.announcements) { a in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(a.title).font(.display(21, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                            Text(a.date).font(.body(14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary)
                            Text(a.body).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary).padding(.top, 2)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func comingUp(_ others: [EventItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Coming up")
            if others.isEmpty {
                EmptyNote(text: "Nothing else is scheduled yet. New events are posted here and shared on WhatsApp.")
            } else {
                RowList {
                    ForEach(others) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.title).font(.display(20, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                            Text([e.tag, e.when].compactMap { $0 }.joined(separator: " · "))
                                .font(.body(14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary)
                            Text(e.detail).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary).padding(.top, 2)
                            if let n = e.note { Text(n).font(.body(14, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary) }
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
