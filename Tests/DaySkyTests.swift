import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Day sky")
struct DaySkyTests {
    private func sky(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> DaySky {
        let day = TestClock.date(y, mo, d)
        let today = PrayerCalculator.schedule(for: day)
        let tomorrow = PrayerCalculator.schedule(for: PrayerCalculator.tomorrow(after: today.date))
        return DaySky.at(TestClock.date(y, mo, d, h, mi), today: today, tomorrow: tomorrow)
    }

    private let gold = DaySky.RGB(r: 0.878, g: 0.690, b: 0.290)
    private let secondary = DaySky.RGB(r: 0.78, g: 0.85, b: 0.84)
    private let white = DaySky.RGB(r: 1, g: 1, b: 1)

    @Test func sunIsUpAtMiddayAndMoonAtNight() {
        #expect(sky(2026, 10, 23, 12).isDay)
        #expect(!sky(2026, 10, 23, 23).isDay)
        #expect(!sky(2026, 10, 23, 3).isDay)
    }

    @Test func sunPeaksAroundMiddayAndStaysOnTheArc() {
        let noon = sky(2026, 6, 21, 13, 0).progress
        #expect(abs(noon - 0.5) < 0.05)
        for h in 0..<24 {
            let p = sky(2026, 10, 23, h).progress
            #expect((0...1).contains(p))
        }
    }

    /// White, gold and secondary text must stay readable wherever they sit on the gradient, at every time of day
    /// in every season. Gold text sits in the upper 80% (the bottom is the arc and its labels).
    @Test func textStaysReadableOnEverySky() {
        for (mo, d) in [(1, 15), (3, 28), (6, 21), (10, 25), (12, 21)] {
            for h in 0..<24 {
                for m in [0, 20, 40] {
                    let s = sky(2027, mo, d, h, m)
                    for y in stride(from: 0.0, through: 1.0, by: 0.1) {
                        #expect(s.contrast(of: white, at: y) >= 4.5, "white \(mo)/\(d) \(h):\(m) y=\(y)")
                        #expect(s.contrast(of: secondary, at: y) >= 4.5, "secondary \(mo)/\(d) \(h):\(m) y=\(y)")
                        if y <= 0.8 { #expect(s.contrast(of: gold, at: y) >= 4.5, "gold \(mo)/\(d) \(h):\(m) y=\(y)") }
                    }
                }
            }
        }
    }
}
