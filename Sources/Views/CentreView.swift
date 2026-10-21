import SwiftUI

struct CentreView: View {
    /// Minimum tile width grows with text size, so tiles drop to one column instead of breaking words.
    @ScaledMetric(relativeTo: .body) private var tileMinWidth: CGFloat = 160
    private var tiles: [GridItem] { [GridItem(.adaptive(minimum: tileMinWidth), spacing: 12)] }

    var body: some View {
        NavigationStack {
            Screen {
                PageTitle(eyebrow: "Faith · Community · Welcome", title: "Bromley Islamic Centre",
                          subtitle: "A place to pray. A community to belong to.")
                LazyVGrid(columns: tiles, spacing: 12) {
                    tile("Services", "Nikah, counselling, youth, mediation", "square.grid.2x2") { ServicesView() }
                    tile("Volunteer", "Nine ways to serve", "hands.clap") { VolunteerView() }
                    tile("Contact", "Call, email, WhatsApp", "phone") { ContactView() }
                    tile("Our story", "Journey and trustees", "building.columns") { AboutView() }
                }
                RowList {
                    link("Sponsors & partners", "Support a programme", "gift") { SponsorsView() }
                    link("Safeguarding", "Raise a concern, emergency numbers", "shield.lefthalf.filled") { SafeguardingView() }
                    link("Policies", "Plain-English governance", "doc.text") { PoliciesView() }
                }
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle("Online")
                    RowList {
                        ExternalRow(title: "Support the Mosque Fund", icon: "heart", url: Site.mosqueFund, subtitle: "Bromley Needs a Mosque")
                        ExternalRow(title: "Mosque project updates", icon: "hammer", url: Site.page("/updates"))
                        ExternalRow(title: "Madrasah parent & teacher portal", icon: "person.crop.circle", url: Site.madrasahPortal,
                                    subtitle: "Opens the centre’s secure sign-in")
                        ExternalRow(title: "Website", icon: "globe", url: Site.base)
                    }
                }
            }
        }
    }

    private func tile<D: View>(_ title: String, _ subtitle: String, _ icon: String, @ViewBuilder _ dest: @escaping () -> D) -> some View {
        NavigationLink(destination: dest) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.title2).foregroundStyle(Theme.accent).frame(minHeight: 36, alignment: .leading).accessibilityHidden(true)
                Text(title).font(.display(22, weight: .semibold, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.body(14, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2...)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 130, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.stroke))
        }
        .buttonStyle(.plain)
    }

    private func link<D: View>(_ title: String, _ subtitle: String, _ icon: String, @ViewBuilder _ dest: @escaping () -> D) -> some View {
        NavigationLink(destination: dest) { ListRow(title: title, subtitle: subtitle, icon: icon) }
            .buttonStyle(.plain)
    }
}

struct ServicesView: View {
    var body: some View {
        Screen(title: "Services") {
            PageTitle(eyebrow: "Services", title: "Serving our community with care",
                      subtitle: "Support for every stage of life.")
            RowList {
                ForEach(Content.services) { s in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: s.icon).font(.title2).foregroundStyle(Theme.accent).accessibilityHidden(true)
                            Text(s.title).font(.display(23, weight: .semibold, relativeTo: .title2)).foregroundStyle(Theme.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                        }
                        Text(s.summary).font(.body(16)).foregroundStyle(Theme.textPrimary)
                        ForEach(s.points, id: \.self) { p in
                            Label { Text(p).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary) }
                                icon: { Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(Theme.accent) }
                        }
                        Link(destination: URL(string: Site.page(s.path))!) {
                            Label("Enquire or apply on the website", systemImage: "arrow.up.right")
                                .font(.body(15, weight: .bold)).foregroundStyle(Theme.accent)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct VolunteerView: View {
    var body: some View {
        Screen(title: "Volunteer") {
            PageTitle(eyebrow: "Volunteer", title: "Serve your community",
                      subtitle: "“The best of people are those most beneficial to people.”")
            RowList {
                ForEach(Content.volunteerTeams, id: \.0) { InfoRow(title: $0.0, text: $0.1) }
            }
            RowList { ExternalRow(title: "Register as a volunteer", icon: "pencil.and.list.clipboard", url: Site.page("/volunteer"),
                                  subtitle: "Opens the form on our website") }
        }
    }
}

struct SponsorsView: View {
    var body: some View {
        Screen(title: "Sponsors") {
            PageTitle(eyebrow: "Get involved", title: "Sponsors & partners",
                      subtitle: "Sponsor a specific need and share in the reward of every prayer, lesson and gathering it makes possible.")
            RowList {
                ForEach(Content.sponsors, id: \.0) { InfoRow(title: $0.0, text: $0.1) }
            }
            RowList { ExternalRow(title: "Enquire about sponsorship", icon: "envelope", url: Site.page("/sponsors")) }
        }
    }
}

struct AboutView: View {
    var body: some View {
        Screen(title: "Our story") {
            PageTitle(eyebrow: "About us", title: "A community journey, rooted in faith")
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("Our mission")
                Text("To foster a vibrant and inclusive Muslim community that strives for spiritual growth, supports personal development and positively contributes to society.")
                    .font(.body(16)).foregroundStyle(Theme.textSecondary)
                SectionTitle("Our vision").padding(.top, 8)
                Text("To establish Bromley Islamic Centre as a centre of excellence: inspiring people to embrace their faith, contribute meaningfully to society and serve as ambassadors of Islam.")
                    .font(.body(16)).foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("Our journey")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(Content.journey.enumerated()), id: \.offset) { i, j in
                        JourneyStep(when: j.0, title: j.1, text: j.2, last: i == Content.journey.count - 1)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Trustees & leadership")
                RowList { ForEach(Content.trustees) { InfoRow(title: $0.name, detail: $0.role, text: $0.blurb) } }
            }
        }
    }
}

private struct JourneyStep: View {
    let when: String, title: String, text: String, last: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                EightPointStar().fill(Theme.accent).frame(width: 18, height: 18).padding(.top, 3)
                if !last { Rectangle().fill(Theme.divider).frame(width: 2).frame(maxHeight: .infinity) }
            }
            .frame(width: 18)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(when.uppercased()).font(.body(12, weight: .bold, relativeTo: .caption)).tracking(1.2).foregroundStyle(Theme.accent)
                Text(title).font(.display(20, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                Text(text).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, last ? 0 : 22)
            .accessibilityElement(children: .combine)
        }
    }
}

struct SafeguardingView: View {
    private let steps = [
        "If a child or adult is in immediate danger, call 999.",
        "Otherwise, speak to our Safeguarding Officer, Asif Hussain, as soon as possible.",
        "Record what you saw or were told, in the person’s own words, with date and time. Do not investigate yourself.",
        "The Safeguarding Officer will assess the concern and, where needed, refer to Bromley Children’s Social Care or the police.",
        "Concerns about a member of staff or volunteer are referred to the Local Authority Designated Officer (LADO).",
    ]

    var body: some View {
        Screen(title: "Safeguarding") {
            PageTitle(eyebrow: "Safeguarding", title: "Everyone deserves to feel safe here",
                      subtitle: "We are committed to protecting the welfare of every child and adult who learns, worships or volunteers with us.")
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Raising a concern")
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(i + 1)").font(.body(15, weight: .bold)).foregroundStyle(Theme.bg)
                            .frame(width: 28, height: 28).background(Theme.accent, in: Circle())
                            .accessibilityHidden(true)
                        Text(s).font(.body(16)).foregroundStyle(Theme.textPrimary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(i + 1). \(s)")
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Get help now")
                RowList {
                    ExternalRow(title: "Emergency", icon: "phone.fill", url: "tel:999", subtitle: "999")
                    ExternalRow(title: "Bromley Children’s Social Care", icon: "phone", url: "tel:02084617373",
                                subtitle: "020 8461 7373 · out of hours 0300 303 8671")
                    ExternalRow(title: "NSPCC helpline", icon: "phone", url: "tel:08088005000", subtitle: "0808 800 5000")
                    ExternalRow(title: "Childline", icon: "phone", url: "tel:08001111", subtitle: "0800 1111")
                    ExternalRow(title: "Email the Safeguarding Officer", icon: "envelope",
                                url: "mailto:\(Site.email)?subject=Safeguarding", subtitle: "Marked “Safeguarding”")
                }
            }
            Text("Please verify local authority numbers on bromley.gov.uk, as they may change.")
                .font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
        }
    }
}

struct PoliciesView: View {
    var body: some View {
        Screen(title: "Policies") {
            PageTitle(eyebrow: "Governance", title: "How we keep our community safe and accountable")
            RowList { ForEach(Content.policies) { InfoRow(title: $0.title, text: $0.summary) } }
            RowList { ExternalRow(title: "Read the full policies", icon: "doc.text", url: Site.page("/policies")) }
        }
    }
}

struct ContactView: View {
    var body: some View {
        Screen(title: "Contact") {
            PageTitle(eyebrow: "Contact", title: "We would be pleased to hear from you",
                      subtitle: "Ask about prayer locations, events, a first visit or community support.")
            RowList {
                ExternalRow(title: "Call us", icon: "phone", url: "tel:\(Site.phone)", subtitle: Site.phoneDisplay)
                ExternalRow(title: "Email", icon: "envelope", url: "mailto:\(Site.email)", subtitle: Site.email)
                ExternalRow(title: "Join the WhatsApp community", icon: "bubble.left.and.bubble.right", url: Site.whatsapp)
                ExternalRow(title: "Send a message on the website", icon: "square.and.pencil", url: Site.page("/contact"))
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Temporary venues")
                Text("We currently use community spaces across Bromley. Contact us for the confirmed location before travelling.")
                    .font(.body(16)).foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Follow us")
                RowList {
                    ExternalRow(title: "YouTube", icon: "play.rectangle", url: Site.youtube)
                    ExternalRow(title: "Instagram", icon: "camera", url: Site.instagram)
                    ExternalRow(title: "Facebook", icon: "person.2", url: Site.facebook)
                    ExternalRow(title: "X", icon: "at", url: Site.twitter)
                }
            }
            Text("Bromley Islamic Centre Ltd · Company number 15967694 · Registered in England and Wales")
                .font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
        }
    }
}
