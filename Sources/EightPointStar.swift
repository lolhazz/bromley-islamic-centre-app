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
