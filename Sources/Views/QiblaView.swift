import SwiftUI
import CoreLocation

@MainActor
final class QiblaModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double?
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var status: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private static let kaaba = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    override init() {
        super.init()
        manager.delegate = self
        status = manager.authorizationStatus
    }

    var headingAvailable: Bool { CLLocationManager.headingAvailable() }

    func start() {
        if status == .notDetermined { manager.requestWhenInUseAuthorization() }
        manager.requestLocation()
        if headingAvailable { manager.startUpdatingHeading() }
    }

    func stop() { manager.stopUpdatingHeading() }

    /// Bearing to Makkah (degrees clockwise from true north). Falls back to Bromley without location.
    var qiblaBearing: Double {
        let from = coordinate ?? CLLocationCoordinate2D(latitude: PrayerCalculator.latitude, longitude: PrayerCalculator.longitude)
        let φ1 = from.latitude * .pi / 180, φ2 = Self.kaaba.latitude * .pi / 180
        let Δλ = (Self.kaaba.longitude - from.longitude) * .pi / 180
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Degrees to turn to face Makkah, -180...180 (positive = turn right). nil without a heading.
    var turn: Double? {
        guard let heading else { return nil }
        var d = (qiblaBearing - heading).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        Task { @MainActor in
            status = m.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                m.requestLocation()
                if CLLocationManager.headingAvailable() { m.startUpdatingHeading() }
            }
        }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations l: [CLLocation]) {
        Task { @MainActor in coordinate = l.last?.coordinate }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateHeading h: CLHeading) {
        Task { @MainActor in heading = h.trueHeading >= 0 ? h.trueHeading : h.magneticHeading }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {}
}

struct QiblaView: View {
    @StateObject private var model = QiblaModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var aligned: Bool { abs(model.turn ?? 180) <= 3 }

    var body: some View {
        NavigationStack {
            Screen {
                PageTitle(title: "Qibla", subtitle: "The direction of Makkah")
                compass
                    .frame(maxWidth: .infinity)
                readout
            }
            .onAppear { model.start() }
            .onDisappear { model.stop() }
            .sensoryFeedback(.success, trigger: aligned) { _, now in now }
        }
    }

    // MARK: Compass

    private var compass: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, 320)
            let r = size / 2
            ZStack {
                dial(radius: r)
                    .rotationEffect(.degrees(-(model.heading ?? 0)))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: model.heading)
                // Fixed marker: the direction the phone points.
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title3).foregroundStyle(aligned ? Theme.accent : Theme.textPrimary)
                    .offset(y: -r - 14)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(height: 360)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Qibla compass")
        .accessibilityValue(spoken)
    }

    private func dial(radius r: CGFloat) -> some View {
        ZStack {
            Circle().stroke(Theme.stroke, lineWidth: 1).padding(r * 0.18)
            EightPointStar()
                .stroke(aligned ? Theme.accent : Theme.accent.opacity(0.55), lineWidth: aligned ? 3 : 2)
            ForEach(0..<72, id: \.self) { i in
                let major = i % 18 == 0
                Rectangle().fill(Theme.textSecondary.opacity(major ? 0.9 : 0.4))
                    .frame(width: major ? 2 : 1, height: major ? 12 : 6)
                    .offset(y: -(r - 4))
                    .rotationEffect(.degrees(Double(i) * 5))
            }
            ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { i, letter in
                Text(letter).font(.body(15, weight: .bold, relativeTo: .caption))
                    .foregroundStyle(letter == "N" ? Theme.accent : Theme.textSecondary)
                    .rotationEffect(.degrees(-Double(i) * 90 + (model.heading ?? 0)))
                    .offset(y: -(r * 0.62))
                    .rotationEffect(.degrees(Double(i) * 90))
            }
            // Makkah marker at its bearing on the dial, kept upright on screen.
            ZStack {
                Capsule().fill(Theme.accent).frame(width: 4, height: r * 0.5).offset(y: -r * 0.25)
                KaabaMark()
                    .padding(9)
                    .background(Theme.bg, in: Circle())
                    .overlay(Circle().stroke(Theme.accent, lineWidth: 2))
                    .rotationEffect(.degrees((model.heading ?? 0) - model.qiblaBearing))
                    .offset(y: -r * 0.62)
            }
            .rotationEffect(.degrees(model.qiblaBearing))
        }
        .frame(width: r * 2, height: r * 2)
    }

    // MARK: Text readout

    private var readout: some View {
        VStack(spacing: 8) {
            Text("\(Int(model.qiblaBearing.rounded()))°")
                .font(.display(56, weight: .semibold, relativeTo: .largeTitle)).foregroundStyle(Theme.textPrimary)
            Text(caption).font(.body(17, weight: aligned ? .bold : .regular)).foregroundStyle(aligned ? Theme.accent : Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let note { Text(note).font(.body(14, relativeTo: .footnote)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center) }
            if model.status == .denied || model.status == .restricted {
                Link("Open Settings", destination: URL(string: "app-settings:")!)
                    .font(.body(15, weight: .bold)).foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var caption: String {
        guard let turn = model.turn else { return "Makkah is \(Int(model.qiblaBearing.rounded()))° from north" }
        if aligned { return "Facing Makkah" }
        let d = Int(abs(turn).rounded())
        return "Turn \(d)° to the \(turn > 0 ? "right" : "left")"
    }

    private var note: String? {
        switch model.status {
        case .denied, .restricted:
            return "Location is off, so this uses Bromley as your position. Allow location in Settings for a live compass."
        default:
            return model.headingAvailable ? (model.heading == nil ? "Hold your phone flat and move it in a figure of eight to calibrate." : nil)
                                          : "This device has no compass, so the arrow shows the bearing from north."
        }
    }

    private var spoken: String {
        let b = Int(model.qiblaBearing.rounded())
        guard let turn = model.turn else { return "Makkah is \(b) degrees from north." }
        return aligned ? "You are facing Makkah." : "Makkah is \(b) degrees from north. Turn \(Int(abs(turn).rounded())) degrees to the \(turn > 0 ? "right" : "left")."
    }
}

/// A small drawn Kaaba: dark cube with a gold band. Marks Makkah on the dial.
private struct KaabaMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(Color(red: 0.07, green: 0.07, blue: 0.08))
            Rectangle().fill(Theme.accent).frame(height: 4).offset(y: -5)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}
