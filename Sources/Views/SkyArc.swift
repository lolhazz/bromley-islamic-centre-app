import SwiftUI

/// Half-ellipse path of the sun across the sky, left (sunrise) to right (Maghrib).
private struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 64
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let pt = SkyArc.point(t, in: rect.size)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        return p
    }
}

/// Sun or moon travelling its arc between sunrise and Maghrib, with the two times beneath.
/// Hidden from VoiceOver because the same times are in the prayer list.
struct SkyArc: View {
    let sky: DaySky
    let sunrise: Date
    let maghrib: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    static let height: CGFloat = 64
    static let inset: CGFloat = 8

    static func point(_ t: Double, in size: CGSize) -> CGPoint {
        let horizon = size.height - 2, peak: CGFloat = 8
        return CGPoint(x: inset + CGFloat(t) * (size.width - 2 * inset),
                       y: horizon - (horizon - peak) * CGFloat(sin(Double.pi * t)))
    }

    private let cream = Color(red: 0.99, green: 0.93, blue: 0.78)

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let t = shown || reduceMotion ? sky.progress : 0
                let pos = SkyArc.point(t, in: geo.size)
                ZStack {
                    // Ground line and the whole path the sun can take.
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: geo.size.height - 1))
                        p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - 1))
                    }.stroke(.white.opacity(0.18), lineWidth: 1)
                    ArcShape().stroke(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1.5, dash: [2, 5]))
                    // The part already travelled.
                    ArcShape().trim(from: 0, to: t)
                        .stroke(cream.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    body(at: pos)
                }
            }
            .frame(height: SkyArc.height)
            .onAppear { withAnimation(.easeOut(duration: 1.4)) { shown = true } }

            ViewThatFits(in: .horizontal) {
                HStack {
                    label("Sunrise", sunrise)
                    Spacer(minLength: 12)
                    label("Maghrib", maghrib)
                }
                VStack(alignment: .leading, spacing: 2) {
                    label("Sunrise", sunrise)
                    label("Maghrib", maghrib)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func body(at pos: CGPoint) -> some View {
        if sky.isDay {
            Circle().fill(cream.opacity(0.30)).frame(width: 30, height: 30).blur(radius: 6).position(pos)
            Circle().fill(cream).frame(width: 14, height: 14).position(pos)
        } else {
            Circle().fill(cream.opacity(0.16)).frame(width: 28, height: 28).blur(radius: 6).position(pos)
            // Crescent: a disc with a second disc cut out of it.
            Circle().fill(cream).frame(width: 14, height: 14)
                .mask {
                    Circle().frame(width: 14, height: 14)
                        .overlay { Circle().frame(width: 12, height: 12).offset(x: 4, y: -2).blendMode(.destinationOut) }
                        .compositingGroup()
                }
                .position(pos)
        }
    }

    private func label(_ name: String, _ date: Date) -> some View {
        HStack(spacing: 6) {
            Text(name).foregroundStyle(Theme.onHeroSecondary)
            Text(TimeFormat.clock(date)).foregroundStyle(Theme.onHero).monospacedDigit()
        }
        .font(.body(13, weight: .medium, relativeTo: .footnote))
    }
}
