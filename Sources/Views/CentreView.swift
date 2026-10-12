import SwiftUI

struct CentreView: View {
    var body: some View {
        NavigationStack {
            Screen {
                PageTitle(eyebrow: "Faith · Community · Welcome", title: "Bromley Islamic Centre",
                          subtitle: "A place to pray. A community to belong to.")
                VStack(spacing: 10) {
                    nav("Services", "square.grid.2x2", "Nikah, counselling, youth, mediation") { ServicesView() }
                    nav("Volunteer", "hands.clap", "Nine ways to serve") { VolunteerView() }
                    nav("Sponsors & partners", "gift", "Support a programme") { SponsorsView() }
                    nav("Our story & trustees", "building.columns", "Journey and leadership") { AboutView() }
                    nav("Safeguarding", "shield.lefthalf.filled", "Raise a concern, emergency numbers") { SafeguardingView() }
                    nav("Policies", "doc.text", "Plain-English governance") { PoliciesView() }
                    nav("Contact us", "phone", "Call, email, WhatsApp") { ContactView() }
                }
                Eyebrow(text: "Quick links").padding(.top, 4)
                LinkRow(title: "Support the Mosque Fund", icon: "heart", url: Site.mosqueFund,
                        subtitle: "Bromley Needs a Mosque")
                LinkRow(title: "Mosque project updates", icon: "hammer", url: Site.page("/updates"))
                LinkRow(title: "Madrasah parent & teacher portal", icon: "person.crop.circle", url: Site.madrasahPortal,
                        subtitle: "Opens the centre’s secure sign-in")
                LinkRow(title: "Website", icon: "globe", url: Site.base)
            }
        }
    }

    private func nav<D: View>(_ t: String, _ i: String, _ s: String, @ViewBuilder _ dest: @escaping () -> D) -> some View {
        NavigationLink(destination: dest) {
            HStack(spacing: 14) {
                Image(systemName: i).foregroundStyle(Theme.gold).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t).font(.body(16, weight: .medium)).foregroundStyle(.white)
                    Text(s).font(.body(13)).foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.white.opacity(0.5))
            }
            .card(radius: 18)
        }
    }
}

struct ServicesView: View {
    var body: some View {
        Screen(title: "Services") {
            PageTitle(eyebrow: "Services", title: "Serving our community with care",
                      subtitle: "Support for every stage of life.")
            ForEach(Content.services) { s in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: s.icon).font(.title2).foregroundStyle(Theme.gold)
                        Text(s.title).font(.display(22, weight: .medium)).foregroundStyle(.white)
                    }
                    Text(s.summary).font(.body(14)).foregroundStyle(.white.opacity(0.85))
                    ForEach(s.points, id: \.self) { p in
                        Label { Text(p).font(.body(13)).foregroundStyle(.white.opacity(0.75)) }
                            icon: { Image(systemName: "checkmark").font(.caption2).foregroundStyle(Theme.gold) }
                    }
                    Link(destination: URL(string: Site.page(s.path))!) {
                        Text("Enquire or apply on the website").font(.body(14, weight: .bold)).foregroundStyle(Theme.gold)
                    }
                }
                .card()
            }
        }
    }
}

struct VolunteerView: View {
    var body: some View {
        Screen(title: "Volunteer") {
            PageTitle(eyebrow: "Volunteer", title: "Serve your community",
                      subtitle: "“The best of people are those most beneficial to people.”")
            ForEach(Content.volunteerTeams, id: \.0) { t in
                VStack(alignment: .leading, spacing: 4) {
                    Text(t.0).font(.body(16, weight: .bold)).foregroundStyle(.white)
                    Text(t.1).font(.body(14)).foregroundStyle(.white.opacity(0.75))
                }.card(radius: 18)
            }
            LinkRow(title: "Register as a volunteer", icon: "pencil.and.list.clipboard", url: Site.page("/volunteer"),
                    subtitle: "Opens the form on our website")
        }
    }
}

struct SponsorsView: View {
    var body: some View {
        Screen(title: "Sponsors") {
            PageTitle(eyebrow: "Get involved", title: "Sponsors & partners",
                      subtitle: "Sponsor a specific need and share in the reward of every prayer, lesson and gathering it makes possible.")
            ForEach(Content.sponsors, id: \.0) { s in
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.0).font(.body(16, weight: .bold)).foregroundStyle(.white)
                    Text(s.1).font(.body(14)).foregroundStyle(.white.opacity(0.75))
                }.card(radius: 18)
            }
            LinkRow(title: "Enquire about sponsorship", icon: "envelope", url: Site.page("/sponsors"))
        }
    }
}

struct AboutView: View {
    var body: some View {
        Screen(title: "Our story") {
            PageTitle(eyebrow: "About us", title: "A community journey, rooted in faith")
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Our mission")
                Text("To foster a vibrant and inclusive Muslim community that strives for spiritual growth, supports personal development and positively contributes to society.")
                    .font(.body(15)).foregroundStyle(.white.opacity(0.85))
                Eyebrow(text: "Our vision").padding(.top, 6)
                Text("To establish Bromley Islamic Centre as a centre of excellence: inspiring people to embrace their faith, contribute meaningfully to society and serve as ambassadors of Islam.")
                    .font(.body(15)).foregroundStyle(.white.opacity(0.85))
            }.card()
            Eyebrow(text: "Our journey")
            ForEach(Content.journey, id: \.1) { j in
                VStack(alignment: .leading, spacing: 3) {
                    Text(j.0.uppercased()).font(.body(11, weight: .bold)).tracking(1.2).foregroundStyle(Theme.gold)
                    Text(j.1).font(.display(20, weight: .medium)).foregroundStyle(.white)
                    Text(j.2).font(.body(14)).foregroundStyle(.white.opacity(0.75))
                }.card(radius: 18)
            }
            Eyebrow(text: "Trustees & leadership")
            ForEach(Content.trustees) { t in
                VStack(alignment: .leading, spacing: 3) {
                    Text(t.name).font(.body(16, weight: .bold)).foregroundStyle(.white)
                    Text(t.role).font(.body(13, weight: .medium)).foregroundStyle(Theme.gold)
                    Text(t.blurb).font(.body(13)).foregroundStyle(.white.opacity(0.75))
                }.card(radius: 18)
            }
        }
    }
}

struct SafeguardingView: View {
    var body: some View {
        Screen(title: "Safeguarding") {
            PageTitle(eyebrow: "Safeguarding", title: "Everyone deserves to feel safe here",
                      subtitle: "We are committed to protecting the welfare of every child and adult who learns, worships or volunteers with us.")
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Raising a concern")
                ForEach(Array([
                    "If a child or adult is in immediate danger, call 999.",
                    "Otherwise, speak to our Safeguarding Officer, Asif Hussain, as soon as possible.",
                    "Record what you saw or were told, in the person’s own words, with date and time. Do not investigate yourself.",
                    "The Safeguarding Officer will assess the concern and, where needed, refer to Bromley Children’s Social Care or the police.",
                    "Concerns about a member of staff or volunteer are referred to the Local Authority Designated Officer (LADO).",
                ].enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)").font(.body(14, weight: .bold)).foregroundStyle(Theme.tealDeep)
                            .frame(width: 24, height: 24).background(Theme.gold, in: Circle())
                        Text(s).font(.body(14)).foregroundStyle(.white.opacity(0.88))
                    }
                }
            }.card()
            VStack(spacing: 10) {
                LinkRow(title: "Emergency", icon: "phone.fill", url: "tel:999", subtitle: "999")
                LinkRow(title: "NSPCC helpline", icon: "phone", url: "tel:08088005000", subtitle: "0808 800 5000")
                LinkRow(title: "Childline", icon: "phone", url: "tel:08001111", subtitle: "0800 1111")
                LinkRow(title: "Bromley Children’s Social Care", icon: "phone", url: "tel:02084617373",
                        subtitle: "020 8461 7373 · out of hours 0300 303 8671")
                LinkRow(title: "Email the Safeguarding Officer", icon: "envelope",
                        url: "mailto:\(Site.email)?subject=Safeguarding", subtitle: "Marked “Safeguarding”")
            }
            Text("Please verify local authority numbers on bromley.gov.uk, as they may change.")
                .font(.body(12)).foregroundStyle(.white.opacity(0.55))
        }
    }
}

struct PoliciesView: View {
    var body: some View {
        Screen(title: "Policies") {
            PageTitle(eyebrow: "Governance", title: "How we keep our community safe and accountable")
            ForEach(Content.policies) { p in
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.title).font(.body(16, weight: .bold)).foregroundStyle(.white)
                    Text(p.summary).font(.body(14)).foregroundStyle(.white.opacity(0.75))
                }.card(radius: 18)
            }
            LinkRow(title: "Read the full policies", icon: "doc.text", url: Site.page("/policies"))
        }
    }
}

struct ContactView: View {
    var body: some View {
        Screen(title: "Contact") {
            PageTitle(eyebrow: "Contact", title: "We would be pleased to hear from you",
                      subtitle: "Ask about prayer locations, events, a first visit or community support.")
            LinkRow(title: "Call us", icon: "phone", url: "tel:\(Site.phone)", subtitle: Site.phoneDisplay)
            LinkRow(title: "Email", icon: "envelope", url: "mailto:\(Site.email)", subtitle: Site.email)
            LinkRow(title: "Join the WhatsApp community", icon: "bubble.left.and.bubble.right", url: Site.whatsapp)
            LinkRow(title: "Send a message on the website", icon: "square.and.pencil", url: Site.page("/contact"))
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Temporary venues")
                Text("We currently use community spaces across Bromley. Contact us for the confirmed location before travelling.")
                    .font(.body(14)).foregroundStyle(.white.opacity(0.8))
            }.card()
            Eyebrow(text: "Follow us")
            LinkRow(title: "YouTube", icon: "play.rectangle", url: Site.youtube)
            LinkRow(title: "Instagram", icon: "camera", url: Site.instagram)
            LinkRow(title: "Facebook", icon: "person.2", url: Site.facebook)
            LinkRow(title: "X", icon: "at", url: Site.twitter)
            Text("Bromley Islamic Centre Ltd · Company number 15967694 · Registered in England and Wales")
                .font(.body(12)).foregroundStyle(.white.opacity(0.55))
        }
    }
}
