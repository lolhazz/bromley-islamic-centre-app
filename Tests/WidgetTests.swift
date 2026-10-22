import Testing
import SwiftUI
import WidgetKit
@testable import BromleyIslamicCentre

@Suite("Widgets")
struct WidgetTests {
    private func entry(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ m: Int = 0) -> PrayerEntryData {
        PrayerEntryData.make(at: TestClock.date(y, mo, d, h, m))
    }

    @Test func phasesFollowTheDay() {
        let before = entry(2026, 10, 21, 12, 0)     // Dhuhr adhan 12:45
        #expect(before.current.prayer == .dhuhr && before.phase == .upcoming)
        #expect(before.countdownTo == before.current.adhan)

        let waiting = entry(2026, 10, 21, 12, 50)
        #expect(waiting.phase == .iqamah)
        #expect(waiting.countdownTo == waiting.current.iqamah)

        let during = entry(2026, 10, 21, 13, 40)
        #expect(during.phase == .inProgress && during.countdownTo == nil)
    }

    @Test func afterIshaShowsTomorrowsFajrWithTomorrowsList() {
        let e = entry(2026, 10, 21, 22, 0)
        #expect(e.current.prayer == .fajr && e.phase == .upcoming)
        #expect(TestClock.london.component(.day, from: e.current.adhan) == 22)
        #expect(e.entries.allSatisfy { TestClock.london.component(.day, from: $0.adhan) == 22 })
    }

    @Test func progressRingBoundsAreSane() {
        for (h, m) in [(3, 0), (6, 30), (12, 0), (12, 50), (13, 40), (16, 0), (20, 0), (22, 0)] {
            let e = entry(2026, 10, 21, h, m)
            #expect(e.periodStart < e.periodEnd, "bounds at \(h):\(m)")
            let now = TestClock.date(2026, 10, 21, h, m)
            #expect(e.periodStart <= now && now <= e.periodEnd, "now outside period at \(h):\(m)")
        }
    }

    @Test func ramadanLineAppearsOnlyDuringRamadan() {
        #expect(entry(2026, 10, 21, 12).ramadanDay == nil)
        let r = entry(2027, 2, 10, 14)
        #expect(r.ramadanDay == 3)
        #expect(r.imsak < r.entries[0].adhan)
        #expect(r.iftar == r.entries[3].adhan)
    }

    // MARK: Rendering (images are written only when WIDGET_SNAPSHOT_DIR is set)

    @MainActor
    private func render(_ name: String, _ e: PrayerEntryData, _ family: WidgetFamily, size: CGSize) throws {
        let lock = [.accessoryRectangular, .accessoryCircular, .accessoryInline].contains(family)
        let content = ZStack {
            if lock { LinearGradient(colors: [.gray.opacity(0.55), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom) }
            else { WidgetBackground() }
            PrayerWidgetView(entry: e, family: family)
                .padding(lock ? 8 : 16)
                .foregroundStyle(lock ? Color.white : Color.primary)
                .frame(width: size.width, height: size.height, alignment: lock ? .center : .topLeading)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: lock ? 16 : 24, style: .continuous))
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        let image = try #require(renderer.uiImage)
        #expect(image.size.width > 0)
        if let dir = ProcessInfo.processInfo.environment["WIDGET_SNAPSHOT_DIR"], let data = image.pngData() {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try data.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        }
    }

    @MainActor @Test func rendersEveryFamilyInEveryPhase() throws {
        let sizes: [(WidgetFamily, String, CGSize)] = [
            (.systemSmall, "small", CGSize(width: 170, height: 170)),
            (.systemMedium, "medium", CGSize(width: 364, height: 170)),
            (.systemLarge, "large", CGSize(width: 364, height: 382)),
            (.accessoryRectangular, "lock-rect", CGSize(width: 172, height: 76)),
            (.accessoryCircular, "lock-circle", CGSize(width: 76, height: 76)),
            (.accessoryInline, "lock-inline", CGSize(width: 257, height: 26)),
        ]
        let moments: [(String, PrayerEntryData)] = [
            ("upcoming", entry(2026, 10, 21, 12, 0)),
            ("iqamah", entry(2026, 10, 21, 12, 50)),
            ("inprogress", entry(2026, 10, 21, 13, 40)),
            ("ramadan", entry(2027, 2, 10, 14, 0)),
        ]
        for (mname, e) in moments {
            for (family, fname, size) in sizes { try render("\(fname)-\(mname)", e, family, size: size) }
        }
    }
}
