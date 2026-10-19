import SwiftUI

/// Eight-point star (two overlaid squares), the motif from the centre's logo and website.
struct EightPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        for k in 0..<2 {
            for i in 0..<4 {
                let a = (Double(i) * .pi / 2) + (k == 1 ? .pi / 4 : 0) + .pi / 4
                let pt = CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            p.closeSubpath()
        }
        return p
    }
}

/// Tiled star outlines used as a quiet texture. Decorative: hidden from VoiceOver.
struct StarPattern: View {
    var cell: CGFloat = 56
    var lineWidth: CGFloat = 1
    var body: some View {
        Canvas { ctx, size in
            let cols = Int(size.width / cell) + 2, rows = Int(size.height / cell) + 2
            for row in 0..<rows {
                for col in 0..<cols {
                    let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell).insetBy(dx: 6, dy: 6)
                    ctx.stroke(EightPointStar().path(in: rect), with: .foreground, lineWidth: lineWidth)
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Page background: flat adaptive colour with a faint star texture.
struct ScreenBackground: View {
    var body: some View {
        ZStack {
            Theme.bg
            StarPattern()
                .foregroundStyle(Theme.accent.opacity(0.045))
        }
        .ignoresSafeArea()
    }
}

/// Dark teal hero block with a star watermark in the corner. Always dark, in light and dark appearance.
struct HeroCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack(alignment: .bottomTrailing) {
                    Theme.hero
                    EightPointStar()
                        .stroke(Theme.onHeroAccent.opacity(0.22), lineWidth: 1.5)
                        .frame(width: 190, height: 190)
                        .offset(x: 95, y: 95)
                    EightPointStar()
                        .stroke(Theme.onHeroAccent.opacity(0.14), lineWidth: 1.5)
                        .frame(width: 130, height: 130)
                        .offset(x: 70, y: 70)
                }
                .clipped()
                .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

/// Hairline divider in the theme colour.
struct Hairline: View {
    var body: some View { Rectangle().fill(Theme.divider).frame(height: 1).accessibilityHidden(true) }
}

/// Plain list row: icon, title, optional subtitle, chevron or external arrow. No box.
struct ListRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var external = false
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(Theme.accent).frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body(17, weight: .medium)).foregroundStyle(Theme.textPrimary)
                if let subtitle { Text(subtitle).font(.body(14, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary) }
            }
            Spacer(minLength: 8)
            Image(systemName: external ? "arrow.up.right" : "chevron.right")
                .font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

/// External link row (opens in Safari / Phone / Mail).
struct ExternalRow: View {
    let title: String, icon: String, url: String
    var subtitle: String? = nil
    var body: some View {
        Link(destination: URL(string: url)!) { ListRow(title: title, subtitle: subtitle, icon: icon, external: true) }
            .accessibilityHint("Opens outside the app")
    }
}

/// Stack of rows separated by hairlines.
struct RowList<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            Hairline()
            Group(subviews: content) { subviews in
                ForEach(subviews) { subview in
                    subview
                    Hairline()
                }
            }
        }
    }
}

/// Serif section heading. Use instead of repeated gold caps labels.
struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.display(24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// Bordered surface for the few things that deserve a box.
    func surfaceCard(radius: CGFloat = 20, stroke: Color = Theme.stroke) -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(stroke))
    }
}


/// Title and descriptive text row for non-navigating lists (volunteer teams, policies, trustees).
struct InfoRow: View {
    let title: String
    var detail: String? = nil
    var text: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.body(17, weight: .bold)).foregroundStyle(Theme.textPrimary)
            if let detail { Text(detail).font(.body(14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.accent) }
            if let text { Text(text).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary) }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Small status line for content that comes from the committee's online feed.
struct FeedStatus: View {
    @ObservedObject var config: ConfigStore
    var body: some View {
        Group {
            switch config.loadState {
            case .loading:
                HStack(spacing: 8) { ProgressView(); Text("Checking for updates…") }
            case .failed:
                VStack(alignment: .leading, spacing: 6) {
                    Label("Couldn’t check for updates. Showing the last saved information.", systemImage: "wifi.slash")
                    Button("Try again") { Task { await config.refresh() } }
                        .font(.body(15, weight: .bold)).foregroundStyle(Theme.accent)
                }
            case .loaded:
                if let d = config.lastUpdated { Text("Updated \(d.formatted(.relative(presentation: .named)))") }
            case .idle:
                EmptyView()
            }
        }
        .font(.body(13, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary)
    }
}

/// Empty-state message with an optional follow-up link.
struct EmptyNote: View {
    let text: String
    var body: some View {
        Text(text).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
            .padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
    }
}
