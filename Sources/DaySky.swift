import SwiftUI

/// The sky over Bromley at a moment in the day: gradient colours plus where the sun (or moon) sits on its arc.
/// `SkyArc` and `HeroCard` draw it. The gradients stay dark enough for white and gold text.
struct DaySky: Equatable {
    struct RGB: Equatable {
        var r: Double, g: Double, b: Double
        var color: Color { Color(red: r, green: g, blue: b) }
        func mixed(with o: RGB, by t: Double) -> RGB {
            RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t)
        }
        var luminance: Double {
            func lin(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
        }
    }

    var top: RGB
    var bottom: RGB
    /// 0 at the start of the arc (sunrise, or sunset at night), 1 at the end.
    var progress: Double
    /// Sun on the arc by day, moon by night.
    var isDay: Bool

    static let night = (top: RGB(r: 0.008, g: 0.102, b: 0.133), bottom: RGB(r: 0.016, g: 0.200, b: 0.220))
    static let dawn = (top: RGB(r: 0.055, g: 0.165, b: 0.255), bottom: RGB(r: 0.200, g: 0.275, b: 0.360))
    static let sunrise = (top: RGB(r: 0.082, g: 0.247, b: 0.298), bottom: RGB(r: 0.290, g: 0.210, b: 0.190))
    static let day = (top: RGB(r: 0.000, g: 0.270, b: 0.267), bottom: RGB(r: 0.008, g: 0.305, b: 0.300))
    static let lateDay = (top: RGB(r: 0.000, g: 0.255, b: 0.255), bottom: RGB(r: 0.150, g: 0.300, b: 0.255))
    static let dusk = (top: RGB(r: 0.071, g: 0.188, b: 0.275), bottom: RGB(r: 0.300, g: 0.185, b: 0.150))

    static func at(_ now: Date, today: DaySchedule, tomorrow: DaySchedule) -> DaySky {
        let fajr = today.entries[0].adhan, asr = today.entries[2].adhan
        let maghrib = today.entries[3].adhan, isha = today.entries[4].adhan
        let sunrise = today.sunrise
        let stops: [(Date, (top: RGB, bottom: RGB))] = [
            (fajr.addingTimeInterval(-30 * 60), night),
            (fajr, dawn),
            (sunrise, DaySky.sunrise),
            (sunrise.addingTimeInterval(75 * 60), day),
            (asr, lateDay),
            (maghrib, dusk),
            (isha, night),
        ]
        var colours = night
        if now >= stops[0].0, now < stops[stops.count - 1].0 {
            for i in 0..<(stops.count - 1) where now >= stops[i].0 && now < stops[i + 1].0 {
                let span = stops[i + 1].0.timeIntervalSince(stops[i].0)
                let t = span > 0 ? now.timeIntervalSince(stops[i].0) / span : 0
                colours = (stops[i].1.top.mixed(with: stops[i + 1].1.top, by: t),
                           stops[i].1.bottom.mixed(with: stops[i + 1].1.bottom, by: t))
            }
        }

        let isDay = now >= sunrise && now < maghrib
        let start: Date, end: Date
        if isDay { (start, end) = (sunrise, maghrib) }
        else if now >= maghrib { (start, end) = (maghrib, tomorrow.sunrise) }
        else { (start, end) = (maghrib.addingTimeInterval(-24 * 3600), sunrise) }
        let p = min(1, max(0, now.timeIntervalSince(start) / end.timeIntervalSince(start)))
        return DaySky(top: colours.top, bottom: colours.bottom, progress: p, isDay: isDay)
    }

    func colour(at y: Double) -> RGB { top.mixed(with: bottom, by: y) }

    func contrast(of text: RGB, at y: Double) -> Double {
        let a = text.luminance, b = colour(at: y).luminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
