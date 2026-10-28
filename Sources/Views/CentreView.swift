import SwiftUI

enum CentreRoute: String, Hashable {
    case services, volunteer, sponsors, story, safeguarding, policies, contact
}

struct CentreView: View {
    @State private var path: [CentreRoute] = DebugRoute.value(after: "-centre").flatMap(CentreRoute.init).map { [$0] } ?? []

    var body: some View {
        NavigationStack(path: $path) {
            Screen {
                PageTitle(title: "The centre")
                mosqueFund
                RowList(stagger: true) {
                    row("Services", "Nikah, counselling, youth club, mediation", .services)
                    row("Volunteer", "Nine teams you can join", .volunteer)
                    row("Contact", "Call, email or WhatsApp", .contact)
                    row("Our story", "How the centre began, and who runs it", .story)
                    row("Sponsors and partners", "Support a specific programme", .sponsors)
                    row("Safeguarding", "How to raise a concern, and who to call", .safeguarding)
                    row("Policies", "In plain English", .policies)
                }
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle("Online")
                    RowList {
                        ExternalRow(title: "Madrasah parent and teacher portal", url: Site.madrasahPortal, subtitle: "Opens the centre’s secure sign-in")
                        ExternalRow(title: "Mosque project updates", url: Site.page("/updates"))
                        ExternalRow(title: "bromleyislamiccentre.org.uk", url: Site.base)
                    }
                }
            }
            .navigationDestination(for: CentreRoute.self) { route in
                switch route {
                case .services: ServicesView()
                case .volunteer: VolunteerView()
                case .sponsors: SponsorsView()
                case .story: AboutView()
                case .safeguarding: SafeguardingView()
                case .policies: PoliciesView()
                case .contact: ContactView()
                }
            }
        }
    }

    /// The centre's live project: buying a permanent masjid. Wording follows the October 2026 update on the website.
    private var mosqueFund: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Bromley needs a mosque")
                    .font(.display(30, weight: .semibold, relativeTo: .title)).foregroundStyle(Theme.onHero)
                Text("The legal checks are done and contracts are about to be exchanged. After that there are about four months to raise the rest.")
                    .font(.body(16, relativeTo: .callout)).foregroundStyle(Theme.onHeroSecondary)
                VStack(alignment: .leading, spacing: 14) {
                    Link(destination: URL(string: Site.mosqueFund)!) {
                        Text("Support the Mosque Fund").font(.body(16, weight: .bold))
                            .foregroundStyle(Theme.hero)
                            .padding(.horizontal, 20).padding(.vertical, 13)
                            .background(Theme.cream, in: Capsule())
                    }
                    Link("Read the update", destination: URL(string: Site.page("/updates"))!)
                        .font(.body(15, weight: .medium)).foregroundStyle(Theme.onHero)
                }
                .padding(.top, 6)
            }
        }
    }

    private func row(_ title: String, _ subtitle: String, _ route: CentreRoute) -> some View {
        NavigationLink(value: route) { ListRow(title: title, subtitle: subtitle) }
            .buttonStyle(RowPressStyle())
    }
}

struct ServicesView: View {
    var body: some View {
        Screen {
            PageTitle(title: "Services")
            RowList {
                ForEach(Content.services) { s in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(s.title).font(.display(24, weight: .semibold, relativeTo: .title2)).foregroundStyle(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(s.summary).font(.body(16)).foregroundStyle(Theme.textPrimary)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(s.points, id: \.self) { p in
                                Text(p).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Link(destination: URL(string: Site.page(s.path))!) {
                            Text("Enquire or apply on the website ↗").font(.body(15, weight: .bold)).foregroundStyle(Theme.accent)
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
        Screen {
            PageTitle(title: "Volunteer")
            Text("“The best of people are those most beneficial to people.”")
                .font(.display(20, relativeTo: .title3)).foregroundStyle(Theme.textSecondary)
            RowList {
                ForEach(Content.volunteerTeams, id: \.0) { InfoRow(title: $0.0, text: $0.1) }
            }
            RowList { ExternalRow(title: "Register as a volunteer", url: Site.page("/volunteer"), subtitle: "Opens the form on our website") }
        }
    }
}

struct SponsorsView: View {
    var body: some View {
        Screen {
            PageTitle(title: "Sponsors and partners")
            Text("Local businesses, families and individuals help our programmes thrive. Sponsor a specific need and share in the reward of every prayer, lesson and gathering it makes possible.")
                .font(.body(16)).foregroundStyle(Theme.textSecondary)
            RowList {
                ForEach(Content.sponsors, id: \.0) { InfoRow(title: $0.0, text: $0.1) }
            }
            RowList { ExternalRow(title: "Enquire about sponsorship", url: Site.page("/sponsors")) }
        }
    }
}

struct AboutView: View {
    var body: some View {
        Screen {
            PageTitle(title: "Our story")
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("Our mission")
                Text("To foster a vibrant and inclusive Muslim community that strives for spiritual growth, supports personal development and positively contributes to society.")
                    .font(.body(16)).foregroundStyle(Theme.textSecondary)
                SectionTitle("Our vision").padding(.top, 8)
                Text("To establish Bromley Islamic Centre as a centre of excellence: inspiring people to embrace their faith, contribute meaningfully to society and serve as ambassadors of Islam.")
                    .font(.body(16)).foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("How we got here")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(Content.journey.enumerated()), id: \.offset) { i, j in
                        JourneyStep(when: j.0, title: j.1, text: j.2, last: i == Content.journey.count - 1)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Trustees and leadership")
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
                EightPointStar().fill(Theme.accent).frame(width: 16, height: 16).padding(.top, 5)
                if !last { Rectangle().fill(Theme.divider).frame(width: 2).frame(maxHeight: .infinity) }
            }
            .frame(width: 16)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.display(21, weight: .medium, relativeTo: .title3)).foregroundStyle(Theme.textPrimary)
                Text(when).font(.body(14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary)
                Text(text).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, last ? 0 : 24)
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
        Screen {
            PageTitle(title: "Safeguarding",
                      subtitle: "We are committed to protecting the welfare of every child and adult who learns, worships or volunteers with us.")
            Link(destination: URL(string: "tel:999")!) {
                Text("In immediate danger? Call 999").font(.body(17, weight: .bold)).foregroundStyle(Theme.onHero)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.hero, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("If you have a concern")
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(i + 1)").font(.display(22, weight: .semibold)).foregroundStyle(Theme.textSecondary)
                            .frame(width: 24, alignment: .leading).accessibilityHidden(true)
                        Text(s).font(.body(16)).foregroundStyle(Theme.textPrimary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(i + 1). \(s)")
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Who to call")
                RowList {
                    ExternalRow(title: "Bromley Children’s Social Care", url: "tel:02084617373",
                                subtitle: "020 8461 7373 · out of hours 0300 303 8671")
                    ExternalRow(title: "NSPCC helpline", url: "tel:08088005000", subtitle: "0808 800 5000")
                    ExternalRow(title: "Childline", url: "tel:08001111", subtitle: "0800 1111")
                    ExternalRow(title: "Email the Safeguarding Officer", url: "mailto:\(Site.email)?subject=Safeguarding", subtitle: "Marked “Safeguarding”")
                }
            }
            Text("Please check local authority numbers on bromley.gov.uk, as they may change.")
                .font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
        }
    }
}

struct PoliciesView: View {
    var body: some View {
        Screen {
            PageTitle(title: "Policies")
            RowList { ForEach(Content.policies) { InfoRow(title: $0.title, text: $0.summary) } }
            RowList { ExternalRow(title: "Read the full policies", url: Site.page("/policies")) }
        }
    }
}

struct ContactView: View {
    var body: some View {
        Screen {
            PageTitle(title: "Contact")
            RowList {
                ExternalRow(title: "Call us", url: "tel:\(Site.phone)", subtitle: Site.phoneDisplay)
                ExternalRow(title: "Email", url: "mailto:\(Site.email)", subtitle: Site.email)
                ExternalRow(title: "Join the WhatsApp community", url: Site.whatsapp, subtitle: "Event, prayer and venue announcements")
                ExternalRow(title: "Send a message on the website", url: Site.page("/contact"))
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Temporary venues")
                Text("We currently use community spaces across Bromley. Contact us for the confirmed location before travelling.")
                    .font(.body(16)).foregroundStyle(Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Follow us")
                RowList {
                    ExternalRow(title: "YouTube", url: Site.youtube)
                    ExternalRow(title: "Instagram", url: Site.instagram)
                    ExternalRow(title: "Facebook", url: Site.facebook)
                    ExternalRow(title: "X", url: Site.twitter)
                }
            }
            Text("Bromley Islamic Centre Ltd · Company number 15967694 · Registered in England and Wales")
                .font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
        }
    }
}
