import SwiftUI

enum Theme {
    static let teal = Color(red: 0.000, green: 0.282, blue: 0.275)
    static let tealDeep = Color(red: 0.008, green: 0.133, blue: 0.157)
    static let gold = Color(red: 0.851, green: 0.647, blue: 0.227)
    static let cream = Color(red: 0.984, green: 0.973, blue: 0.945)
    static let ink = Color(red: 0.07, green: 0.12, blue: 0.13)
}

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold: name = "Newsreader-SemiBold"
        case .medium: name = "Newsreader-Medium"
        default: name = "Newsreader-Regular"
        }
        return .custom(name, size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .semibold: name = "DMSans-Bold"
        case .medium: name = "DMSans-Medium"
        default: name = "DMSans-Regular"
        }
        return .custom(name, size: size)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.body(12, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(Theme.gold)
    }
}

struct ScreenBackground: View {
    var body: some View {
        LinearGradient(colors: [Theme.teal, Theme.tealDeep], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
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
