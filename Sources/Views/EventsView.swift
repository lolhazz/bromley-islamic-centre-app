import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var config: ConfigStore

    private var featured: EventItem? { config.events.first { $0.when != nil } }
    private var others: [EventItem] { config.events.filter { $0.id != featured?.id } }

    var body: some View {
        NavigationStack {
            Screen {
                PageTitle(title: "What’s on",
                          subtitle: "Gather, learn and grow together.")
                if let featured { featuredCard(featured) }
                announcements
                comingUp
                FeedStatus(config: config)
                RowList {
                    ExternalRow(title: "Join the WhatsApp community",
                                url: Site.whatsapp, subtitle: "Event, prayer and venue announcements")
                    ExternalRow(title: "Khutbahs and talks", url: Site.page("/videos"),
                                subtitle: "Video library and live Jumu’ah")
                }
            }
            .refreshable { await config.refresh() }
        }
    }

    private func featuredCard(_ e: EventItem) -> some View {
        HeroCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(e.tag.uppercased()).font(.body(12, weight: .bold)).tracking(1.6).foregroundStyle(Theme.onHeroAccent)
                Text(e.title).font(.display(30, weight: .semibold, relativeTo: .title)).foregroundStyle(Theme.onHero)
                if let w = e.when {
                    Label(w, systemImage: "calendar").font(.body(15, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.onHero)
                }
                Text(e.detail).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.onHeroSecondary)
                if let n = e.note { Text(n).font(.body(14, relativeTo: .footnote)).italic().foregroundStyle(Theme.onHeroAccent) }
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
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.date.uppercased()).font(.body(12, weight: .bold, relativeTo: .caption)).tracking(1.2).foregroundStyle(Theme.accent)
                            Text(a.title).font(.display(21, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                            Text(a.body).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var comingUp: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Coming up")
            if others.isEmpty {
                EmptyNote(text: "Nothing else is scheduled yet. New events are posted here and shared on WhatsApp.")
            } else {
                RowList {
                    ForEach(others) { e in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(e.tag.uppercased()).font(.body(12, weight: .bold, relativeTo: .caption)).tracking(1.2).foregroundStyle(Theme.accent)
                            Text(e.title).font(.display(20, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                            if let w = e.when {
                                Label(w, systemImage: "calendar").font(.body(14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.textPrimary)
                            }
                            Text(e.detail).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
                            if let n = e.note { Text(n).font(.body(14, relativeTo: .footnote)).italic().foregroundStyle(Theme.textSecondary) }
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
