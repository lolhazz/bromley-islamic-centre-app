import Foundation

enum Site {
    static let base = "https://bromleyislamiccentre.org.uk"
    static let whatsapp = "https://chat.whatsapp.com/KTQ0Bfyft5sAykfGXeJiLK?mode=gi_t"
    static let youtubeLive = "https://www.youtube.com/@bromleyislamiccentre/live"
    static let youtube = "https://www.youtube.com/@bromleyislamiccentre"
    static let instagram = "https://instagram.com/bromleyislamiccentre"
    static let facebook = "https://facebook.com/bromleyislamiccentre"
    static let twitter = "https://twitter.com/Bromleyislamic"
    static let mosqueFund = "https://bromleyneedsamosque.org.uk/"
    static let madrasahPortal = base + "/madrasah-login"
    static let phone = "+442034883310"
    static let phoneDisplay = "0203 488 3310"
    static let email = "info@bromleyislamiccentre.org.uk"
    static func page(_ path: String) -> String { base + path }
}

struct Announcement: Identifiable, Codable {
    var id: String { date + title }
    let title: String
    let body: String
    let date: String
}

struct EventItem: Identifiable, Codable {
    var id: String { tag + title }
    let tag: String
    let title: String
    let detail: String
    let when: String?
    let note: String?
}

struct JumuahSlot: Identifiable, Codable {
    var id: String { label }
    let label: String
    let khutbah: String
    let jamaah: String
    let venue: String?
    let note: String?
}

struct ServiceItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let summary: String
    let points: [String]
    let path: String
}

struct Trustee: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let blurb: String
}

struct PolicyItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
}

/// Static content mirrored from bromleyislamiccentre.org.uk (checked 9 Oct 2026).
/// Replace `announcements`/`events` with a live feed once the committee has an admin source.
enum Content {
    static let jumuah: [JumuahSlot] = [
        JumuahSlot(label: "1st Jumu’ah", khutbah: "1:15 pm", jamaah: "1:30 pm", venue: nil, note: nil),
        JumuahSlot(label: "2nd Jumu’ah", khutbah: "2:00 pm", jamaah: "2:15 pm", venue: nil, note: nil),
    ]

    static let venueBanner = "We currently meet in temporary community spaces. Confirm the venue before you travel."

    static let announcements: [Announcement] = [
        Announcement(title: "Mosque project moves closer to exchange",
                     body: "Legal due diligence is complete and we are preparing to exchange contracts. After exchange we have about four months to raise the remaining funds. The hope is to complete before Ramadan.",
                     date: "October 2026"),
        Announcement(title: "Guest imam this Friday",
                     body: "Shaykh Abu Muhammad Saleh delivers the first Jumu’ah khutbah on Fri 23 October at 1:15 pm. Brothers only for the first Jumu’ah. Please arrive early.",
                     date: "23 October 2026"),
        Announcement(title: "The purchase process has begun",
                     body: "Solicitors have been instructed and are progressing the legal work before exchange of contracts.",
                     date: "June 2026"),
    ]

    static let events: [EventItem] = [
        EventItem(tag: "Guest imam", title: "Shaykh Abu Muhammad Saleh",
                  detail: "Graduate of the Faculty of Shari’ah at the Islamic University of Madinah, with a Master’s in Usul al-Fiqh. Delivers the first Jumu’ah khutbah.",
                  when: "Fri 23 Oct 2026 · 1:15 pm", note: "Brothers only for the first Jumu’ah. Arrive early."),
        EventItem(tag: "Special guest", title: "Shaikh Ismail",
                  detail: "Al-Azhar graduate, well known to Bromley’s Muslim community. A gathering to support the future of the Masjid.",
                  when: nil, note: "Date to be announced."),
        EventItem(tag: "Weekly", title: "Community lecture",
                  detail: "A weekly space for learning, reflection and questions.",
                  when: nil, note: "Speaker and venue announced shortly."),
        EventItem(tag: "Sundays", title: "Weekend Madrasah",
                  detail: "Ages 5 to 17. Quran, Salah, Islamic studies and Arabic.",
                  when: "Sundays · registration 2:45 pm · finish 5:00 pm", note: nil),
        EventItem(tag: "Young people", title: "Youth classes and NextGen",
                  detail: "Learning, sports, outings and mentoring in a safe, supervised space.",
                  when: nil, note: "Activities announced through community channels."),
        EventItem(tag: "In Ramadan", title: "Community iftar",
                  detail: "Break your fast together.", when: nil, note: "Timing and venue shared before Ramadan."),
        EventItem(tag: "Ramadan nights", title: "Taraweeh prayers",
                  detail: "Nightly in congregation throughout Ramadan.", when: nil, note: "Venue and timings announced before the month begins."),
    ]

    static let services: [ServiceItem] = [
        ServiceItem(icon: "heart.text.square", title: "Marriage services",
                    summary: "Nikah ceremonies, applications and marriage counselling.",
                    points: ["Photo ID for groom, bride, wali and two witnesses", "The bride’s wali takes part", "A nikah may not by itself be legally recognised in England and Wales, so also arrange a civil marriage", "Submitting is an application, not a confirmed booking"],
                    path: "/services?tab=marriage"),
        ServiceItem(icon: "figure.2.and.child.holdinghands", title: "NextGen youth club",
                    summary: "Youth club, activities, outings and mentoring.",
                    points: ["Sports, games and social activities", "Faith-based learning circles", "Positive role models and mentoring", "Run in line with our safeguarding policy"],
                    path: "/services?tab=nextgen"),
        ServiceItem(icon: "ear", title: "Counselling",
                    summary: "Personal, family and spiritual support in confidence.",
                    points: ["Personal and family matters", "Spiritual guidance", "Signposting to specialist services", "Strictly confidential"],
                    path: "/services?tab=counselling"),
        ServiceItem(icon: "scale.3d", title: "Mediation & arbitration",
                    summary: "Resolving disputes fairly between partners and families.",
                    points: ["Business partner disputes", "Family and community disagreements", "A neutral, faith-grounded process"],
                    path: "/services?tab=mediation"),
        ServiceItem(icon: "book.closed", title: "Weekend Madrasah",
                    summary: "Sundays for boys and girls aged 5 to 17.",
                    points: ["Registration 2:45 pm, finish 5:00 pm", "Quran with Tajweed, Salah, Islamic studies, Arabic", "Safeguarding and DBS-checked teachers"],
                    path: "/madrasah"),
        ServiceItem(icon: "sparkles", title: "Discover Islam",
                    summary: "Questions are always welcome.",
                    points: ["Ask anything, in private", "Free English Quran on request", "New Muslim care and one-to-one mentoring"],
                    path: "/discover-islam"),
    ]

    static let volunteerTeams: [(String, String)] = [
        ("Masjid cleaning & care", "Carpets, shoe areas, wudu areas and supplies."),
        ("Madrasah teachers", "Quran, etiquette and stories on Sundays. DBS check required."),
        ("Classroom support", "Registration, activities and worksheets. DBS check required."),
        ("Jumu’ah & event stewarding", "Set up, welcome worshippers and pack away."),
        ("Ramadan iftars", "Prepare, serve and clear up."),
        ("NextGen youth mentors", "Sports, outings and activities. DBS check required."),
        ("New Muslim & sisters’ support", "Welcome new Muslims and support sisters’ circles."),
        ("First aid", "Qualified first-aiders at Jumu’ah, Taraweeh and busy events."),
        ("Media, sound & admin", "Sound, livestreams, notices and administration."),
    ]

    static let sponsors: [(String, String)] = [
        ("Ramadan iftar sponsor", "Food and supplies for a community iftar."),
        ("Madrasah learning sponsor", "Qurans, Qa’idahs, workbooks and prizes."),
        ("NextGen youth sponsor", "Venue hire, equipment or a trip."),
        ("Facilities & essentials", "Cleaning and hygiene supplies."),
        ("Event sponsor", "A lecture, speaker or gathering."),
        ("Mosque Fund partner", "Pledge towards the permanent masjid."),
    ]

    static let trustees: [Trustee] = [
        Trustee(name: "Omar Mahmood", role: "Chairman & Imam", blurb: "Leads the centre’s vision and governance, and serves as Imam and khateeb."),
        Trustee(name: "Mohammed Vaseem", role: "Deputy Chairman & Imam", blurb: "Supports the Chairman and delivers khutbahs and lessons."),
        Trustee(name: "Muhammad Hanif", role: "Treasurer", blurb: "Oversees finances, donations and accountability."),
        Trustee(name: "Taufique Moten", role: "Deputy Treasurer & Head of Events", blurb: "Supports financial oversight and leads event planning."),
        Trustee(name: "Dr Mohamed Elalfi", role: "Head of Operations", blurb: "Manages day-to-day operations, venues and services."),
        Trustee(name: "Asif Hussain", role: "Head of Community Welfare & Safety", blurb: "Oversees welfare, health and safety. Safeguarding Officer."),
    ]

    static let journey: [(String, String, String)] = [
        ("The early years", "Prayers in the Village Hall", "Jumu’ah and classes in temporary venues."),
        ("A first home", "Brewery Road", "A house for daily prayers, Taraweeh, iftars and lessons."),
        ("A milestone", "Al Emaan Centre", "Established in Keston with community donations and Qard Hasanah."),
        ("Summer 2024", "Bromley Islamic Centre", "Bromley High Street becomes the centre’s home."),
        ("The next chapter", "A permanent masjid", "A central masjid in Bromley North for prayer, education, youth work and family guidance."),
    ]

    static let policies: [PolicyItem] = [
        PolicyItem(title: "Data protection & privacy", summary: "We collect only what we need, keep it secure and never sell it. You can ask to see, correct or delete your data."),
        PolicyItem(title: "Health, safety & venue welfare", summary: "Every gathering, including temporary venues, is risk-assessed with a fire plan and first aid."),
        PolicyItem(title: "Complaints & whistleblowing", summary: "Concerns are heard fairly, confidentially and without retaliation."),
        PolicyItem(title: "Code of conduct", summary: "Courtesy, honesty and care from everyone who serves or visits."),
        PolicyItem(title: "Equality, diversity & inclusion", summary: "Everyone is welcome to visit, learn and ask questions."),
        PolicyItem(title: "Financial controls", summary: "Every donation is counted, banked and recorded transparently."),
        PolicyItem(title: "Political impartiality", summary: "The centre does not support any political party or candidate."),
        PolicyItem(title: "Photography & social media", summary: "No child is photographed or filmed without parental consent."),
        PolicyItem(title: "Conflict of interest", summary: "Trustees declare anything that could affect their judgement."),
        PolicyItem(title: "Risk management", summary: "Main risks to people, money and reputation are identified and reduced."),
        PolicyItem(title: "Serious incident reporting", summary: "Reported promptly to trustees and, where required, the authorities."),
        PolicyItem(title: "Fundraising & donations", summary: "We fundraise honestly and use every donation as intended."),
        PolicyItem(title: "Volunteer policy", summary: "Volunteers are welcomed, supported and safely recruited."),
    ]
}
