import SwiftUI

enum Theme {
    static let teal = Color(red: 0.000, green: 0.282, blue: 0.275)
    static let tealDeep = Color(red: 0.008, green: 0.133, blue: 0.157)
    static let gold = Color(red: 0.851, green: 0.647, blue: 0.227)
    static let cream = Color(red: 0.984, green: 0.973, blue: 0.945)
    static let ink = Color(red: 0.07, green: 0.12, blue: 0.13)

    // Adaptive tokens (light and dark variants live in Assets.xcassets).
    static let bg = Color("Bg")
    static let surface = Color("Surface")
    static let stroke = Color("Stroke")
    static let divider = Color("Divider")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    /// Gold for text and icons: darker in light mode so it stays readable on cream.
    static let accent = Color("AccentText")
    /// The always-dark teal used for hero blocks in both appearances.
    static let hero = Color("Hero")
    /// Text colours that sit on `hero`.
    static let onHero = Color.white
    static let onHeroSecondary = Color(red: 0.78, green: 0.85, blue: 0.84)
    static let onHeroAccent = Color(red: 0.878, green: 0.690, blue: 0.290)
}

extension Font {
    /// Newsreader, scales with Dynamic Type relative to `style`.
    static func display(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .title2) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold: name = "Newsreader-SemiBold"
        case .medium: name = "Newsreader-Medium"
        default: name = "Newsreader-Regular"
        }
        return .custom(name, size: size, relativeTo: style)
    }

    /// DM Sans, scales with Dynamic Type relative to `style`.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let name: String
        switch weight {
        case .bold, .semibold: name = "DMSans-Bold"
        case .medium: name = "DMSans-Medium"
        default: name = "DMSans-Regular"
        }
        return .custom(name, size: size, relativeTo: style)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.body(12, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(Theme.accent)
    }
}

extension View {
    func card(radius: CGFloat = 22, stroke: Color = .white.opacity(0.12)) -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(stroke))
    }
}

struct Screen<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) { content }
                    .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .toolbarBackground(Theme.teal, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title ?? "")
    }
}

struct LinkRow: View {
    let title: String, icon: String, url: String
    var subtitle: String? = nil
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: icon).foregroundStyle(Theme.gold).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body(16, weight: .medium)).foregroundStyle(.white)
                    if let subtitle { Text(subtitle).font(.body(13)).foregroundStyle(.white.opacity(0.65)) }
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(.white.opacity(0.5))
            }
            .card(radius: 18)
        }
    }
}

struct PageTitle: View {
    let eyebrow: String, title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: eyebrow)
            Text(title).font(.display(32, weight: .semibold)).foregroundStyle(.white)
            if let subtitle { Text(subtitle).font(.body(16)).foregroundStyle(.white.opacity(0.8)) }
        }
    }
}
