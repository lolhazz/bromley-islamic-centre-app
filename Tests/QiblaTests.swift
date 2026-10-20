import Testing
import CoreLocation
@testable import BromleyIslamicCentre

@MainActor
@Suite("Qibla")
struct QiblaTests {
    @Test func bearingFromBromleyIsSouthEastAround119Degrees() {
        let m = QiblaModel()
        #expect(m.qiblaBearing > 118 && m.qiblaBearing < 120)   // London's great-circle bearing is about 119 degrees
    }

    @Test func bearingFromKnownCities() {
        let m = QiblaModel()
        m.coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)   // New York
        #expect(m.qiblaBearing > 55 && m.qiblaBearing < 60)
        m.coordinate = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)  // Sydney
        #expect(m.qiblaBearing > 275 && m.qiblaBearing < 285)
    }

    @Test func turnIsNilWithoutHeading() {
        #expect(QiblaModel().turn == nil)
    }

    @Test func turnDirectionAndWraparound() {
        let m = QiblaModel()
        let b = m.qiblaBearing
        m.heading = b - 40
        #expect(abs(m.turn! - 40) < 0.001)          // turn right
        m.heading = b + 25
        #expect(abs(m.turn! + 25) < 0.001)          // turn left
        m.heading = b
        #expect(abs(m.turn!) < 0.001)               // aligned
        m.heading = (b + 180).truncatingRemainder(dividingBy: 360)
        #expect(abs(abs(m.turn!) - 180) < 0.001)    // behind you
        m.heading = 359
        m.coordinate = CLLocationCoordinate2D(latitude: 51.4060, longitude: 0.0148)
        #expect(m.turn! > -180 && m.turn! <= 180)
    }
}
