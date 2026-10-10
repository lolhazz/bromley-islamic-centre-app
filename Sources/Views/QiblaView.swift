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

    func start() {
        if status == .notDetermined { manager.requestWhenInUseAuthorization() }
        manager.requestLocation()
        manager.startUpdatingHeading()
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

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        Task { @MainActor in
            status = m.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways { m.requestLocation(); m.startUpdatingHeading() }
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

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Eyebrow(text: "Qibla")
                    Text("Direction of Makkah").font(.display(30, weight: .semibold)).foregroundStyle(.white)
                }
                compass
                Text(caption).font(.body(14)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 40)
        }
        .preferredColorScheme(.dark)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private var rotation: Double {
        // Needle points to Qibla relative to the phone's heading; without a heading it points at the bearing from north.
        model.qiblaBearing - (model.heading ?? 0)
    }

    private var compass: some View {
        ZStack {
            Circle().stroke(Theme.gold.opacity(0.4), lineWidth: 2)
            Circle().stroke(.white.opacity(0.1), lineWidth: 1).padding(28)
            ForEach(0..<36) { i in
                Rectangle().fill(.white.opacity(i % 9 == 0 ? 0.7 : 0.25))
                    .frame(width: 2, height: i % 9 == 0 ? 14 : 7)
                    .offset(y: -142).rotationEffect(.degrees(Double(i) * 10))
            }
            VStack(spacing: 0) {
                Image(systemName: "location.north.fill").font(.system(size: 54)).foregroundStyle(Theme.gold)
                Capsule().fill(Theme.gold.opacity(0.5)).frame(width: 3, height: 70)
            }
            .offset(y: -20)
            .rotationEffect(.degrees(rotation))
            .animation(.easeOut(duration: 0.2), value: rotation)
        }
        .frame(width: 300, height: 300)
        .accessibilityLabel("Qibla compass")
        .accessibilityValue("Makkah is \(Int(model.qiblaBearing)) degrees from north")
    }

    private var caption: String {
        let b = Int(model.qiblaBearing.rounded())
        switch model.status {
        case .denied, .restricted:
            return "Makkah is \(b)° from north in Bromley. Allow location in Settings for live compass guidance."
        default:
            return model.heading == nil
                ? "Makkah is \(b)° from north. Hold your phone flat to use the live compass."
                : "Turn until the arrow points straight up. Makkah is \(b)° from north."
        }
    }
}
