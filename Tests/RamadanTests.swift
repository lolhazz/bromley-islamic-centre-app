import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Ramadan")
struct RamadanTests {
    @Test func farFromRamadanIsNone() {
        guard case .none = Ramadan.state(now: TestClock.date(2026, 10, 23), override: nil) else { Issue.record("expected none"); return }
    }

    @Test func countdownBeginsThirtyDaysBefore() {
        // Umm al-Qura: Ramadan 1448 starts 8 Feb 2027.
        guard case .before(let d) = Ramadan.state(now: TestClock.date(2027, 1, 15), override: nil) else { Issue.record("expected before"); return }
        #expect(d == 24)
    }

    @Test func dayCounterDuringRamadan() {
        guard case .during(let day) = Ramadan.state(now: TestClock.date(2027, 2, 10), override: nil) else { Issue.record("expected during"); return }
        #expect(day == 3)
    }

    @Test func overrideMovesTheStart() {
        // Moon sighting puts day 1 on 9 Feb: 10 Feb is day 2.
        guard case .during(let day) = Ramadan.state(now: TestClock.date(2027, 2, 10), override: "2027-02-09") else { Issue.record("expected during"); return }
        #expect(day == 2)
    }

    @Test func endsAfterThirtyDays() {
        guard case .none = Ramadan.state(now: TestClock.date(2027, 3, 12), override: "2027-02-09") else { Issue.record("expected none"); return }
    }

    @Test func invalidOverrideFallsBackToCalendar() {
        guard case .during(let day) = Ramadan.state(now: TestClock.date(2027, 2, 10), override: "not-a-date") else { Issue.record("expected during"); return }
        #expect(day == 3)
    }

    @Test func isDuringMatchesState() {
        #expect(Ramadan.isDuring(TestClock.date(2027, 2, 20), override: nil))
        #expect(!Ramadan.isDuring(TestClock.date(2026, 10, 23), override: nil))
    }

    @Test func hijriStringIsNotEmpty() {
        #expect(Ramadan.hijriString(for: TestClock.date(2026, 10, 23)).contains("1448"))
    }
}
