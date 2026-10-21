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

/// Page scaffold: scrolling column on the adaptive background, readable width on iPad.
struct Screen<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { content }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
        }
        .background(ScreenBackground())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title ?? "")
    }
}

struct PageTitle: View {
    let eyebrow: String, title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: eyebrow)
            Text(title).font(.display(34, weight: .semibold, relativeTo: .largeTitle)).foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle { Text(subtitle).font(.body(17)).foregroundStyle(Theme.textSecondary) }
        }
    }
}
