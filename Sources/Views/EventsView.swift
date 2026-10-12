import SwiftUI

struct EventsView: View {
    var body: some View {
        NavigationStack {
            Screen {
                PageTitle(eyebrow: "Community & events", title: "What’s on",
                          subtitle: "Gather, learn and grow together.")
                section("Announcements")
                ForEach(Content.announcements) { a in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(a.date.uppercased()).font(.body(11, weight: .bold)).tracking(1.2).foregroundStyle(Theme.gold)
                        Text(a.title).font(.display(21, weight: .medium)).foregroundStyle(.white)
                        Text(a.body).font(.body(14)).foregroundStyle(.white.opacity(0.82))
                    }
                    .card(stroke: Theme.gold.opacity(0.3))
                }
                section("Coming up")
                ForEach(Content.events) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(e.tag.uppercased()).font(.body(11, weight: .bold)).tracking(1.2).foregroundStyle(Theme.gold)
                        Text(e.title).font(.display(21, weight: .medium)).foregroundStyle(.white)
                        if let w = e.when { Label(w, systemImage: "calendar").font(.body(13, weight: .medium)).foregroundStyle(.white) }
                        Text(e.detail).font(.body(14)).foregroundStyle(.white.opacity(0.82))
                        if let n = e.note { Text(n).font(.body(13)).italic().foregroundStyle(.white.opacity(0.6)) }
                    }
                    .card()
                }
                LinkRow(title: "Join the WhatsApp community", icon: "bubble.left.and.bubble.right",
                        url: Site.whatsapp, subtitle: "Event, prayer and venue announcements")
                LinkRow(title: "Watch khutbahs & talks", icon: "play.rectangle", url: Site.page("/videos"),
                        subtitle: "Video library and live Jumu’ah")
            }
        }
    }

    private func section(_ t: String) -> some View { Eyebrow(text: t).padding(.top, 4) }
}
