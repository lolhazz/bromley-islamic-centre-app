import SwiftUI

/// Tiled star outlines used as a background texture. Hidden from VoiceOver.
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

/// Page background.
struct ScreenBackground: View {
    var body: some View { Theme.bg.ignoresSafeArea() }
}

/// Dark teal hero block with a star watermark in the corner. Always dark, in light and dark appearance.
struct HeroCard<Content: View>: View {
    /// When set, the block is painted with the sky at this moment instead of flat teal.
    var sky: DaySky? = nil
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turning = false
    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack(alignment: sky == nil ? .bottomTrailing : .topTrailing) {
                    if let sky {
                        LinearGradient(colors: [sky.top.color, sky.bottom.color], startPoint: .top, endPoint: .bottom)
                    } else {
                        Theme.hero
                    }
                    // The two stars turn against each other, slowly. Still under Reduce Motion.
                    EightPointStar()
                        .stroke(Theme.onHeroAccent.opacity(0.22), lineWidth: 1.5)
                        .frame(width: 190, height: 190)
                        .rotationEffect(.degrees(turning ? 360 : 0))
                        .offset(x: 95, y: sky == nil ? 95 : -95)
                    EightPointStar()
                        .stroke(Theme.onHeroAccent.opacity(0.14), lineWidth: 1.5)
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(turning ? -360 : 0))
                        .offset(x: 70, y: sky == nil ? 70 : -70)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: 180).repeatForever(autoreverses: false)) { turning = true }
                }
                .clipped()
                .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct Hairline: View {
    var body: some View { Rectangle().fill(Theme.divider).frame(height: 1).accessibilityHidden(true) }
}

/// List row: title, optional subtitle, chevron or external arrow.
struct ListRow: View {
    let title: String
    var subtitle: String? = nil
    var external = false
    var body: some View {
        HStack(spacing: 12) {
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

/// Row press feedback: a soft tint and a light tick.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.stroke.opacity(0.45) : .clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

struct ExternalRow: View {
    let title: String, url: String
    var subtitle: String? = nil
    var body: some View {
        Link(destination: URL(string: url)!) { ListRow(title: title, subtitle: subtitle, external: true) }
            .buttonStyle(RowPressStyle())
            .accessibilityHint("Opens outside the app")
    }
}

struct RowList<Content: View>: View {
    /// Rows rise into place one after another the first time the list appears (skipped under Reduce Motion).
    var stagger = false
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        VStack(spacing: 0) {
            Hairline()
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.element.id) { i, subview in
                    let show = !stagger || reduceMotion || arrived
                    Group {
                        subview
                        Hairline()
                    }
                    .opacity(show ? 1 : 0)
                    .offset(y: show ? 0 : 14)
                    .animation(.easeOut(duration: 0.45).delay(Double(min(i, 8)) * 0.045), value: arrived)
                }
            }
        }
        .onAppear { arrived = true }
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.display(24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// Bordered surface.
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
            if let detail { Text(detail).font(.body(14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(Theme.textSecondary) }
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

struct EmptyNote: View {
    let text: String
    var body: some View {
        Text(text).font(.body(15, relativeTo: .callout)).foregroundStyle(Theme.textSecondary)
            .padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
    }
}
