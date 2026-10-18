import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Next prayer")
struct NextPrayerTests {
    private func resolve(_ h: Int, _ m: Int) -> (NextPrayer, PrayerEntry) {
        let now = TestClock.date(2026, 10, 14, h, m)
        let today = PrayerCalculator.schedule(for: now)
        let tomorrow = PrayerCalculator.schedule(for: PrayerCalculator.tomorrow(after: today.date))
        return NextPrayer.resolve(now: now, schedule: today, tomorrow: tomorrow)
    }

    @Test func beforeFajrCountsDownToFajr() {
        let (state, e) = resolve(3, 0)
        #expect(e.prayer == .fajr)
        guard case .upcoming(_, let secs) = state else { Issue.record("expected upcoming"); return }
        #expect(abs(secs - (2 * 3600 + 50 * 60)) < 90)
    }

    @Test func betweenAdhanAndIqamahCountsToIqamah() {
        let (state, e) = resolve(12, 50)   // Dhuhr adhan 12:46, iqamah 13:32
        #expect(e.prayer == .dhuhr)
        guard case .iqamahSoon(_, let secs) = state else { Issue.record("expected iqamahSoon"); return }
        #expect(abs(secs - 42 * 60) < 90)
    }

    @Test func justAfterIqamahIsJamaahInProgress() {
        let (state, e) = resolve(13, 40)   // iqamah 13:32, still current until 13:47
        #expect(e.prayer == .dhuhr)
        guard case .inProgress = state else { Issue.record("expected inProgress"); return }
    }

    @Test func fifteenMinutesAfterIqamahMovesOn() {
        let (_, e) = resolve(13, 50)
        #expect(e.prayer == .asr)
    }

    @Test func afterIshaRollsToTomorrowsFajr() {
        let (state, e) = resolve(22, 0)
        #expect(e.prayer == .fajr)
        #expect(TestClock.london.component(.day, from: e.adhan) == 15)
        guard case .upcoming(_, let secs) = state else { Issue.record("expected upcoming"); return }
        #expect(secs > 7 * 3600 && secs < 9 * 3600)
    }
}

@Suite("Time formatting")
struct TimeFormatTests {
    @Test func clockUsesLowercaseAmPmInLondon() {
        #expect(TimeFormat.clock(TestClock.date(2026, 10, 14, 6, 5)) == "6:05 am")
        #expect(TimeFormat.clock(TestClock.date(2026, 10, 14, 19, 14)) == "7:14 pm")
        #expect(TimeFormat.clock(TestClock.date(2026, 10, 14, 12, 0)) == "12:00 pm")
    }

    @Test func countdownFormatsMinutesAndHours() {
        #expect(TimeFormat.countdown(0) == "0m")
        #expect(TimeFormat.countdown(59 * 60) == "59m")
        #expect(TimeFormat.countdown(60 * 60) == "1h 0m")
        #expect(TimeFormat.countdown(8 * 3600 + 8 * 60) == "8h 8m")
        #expect(TimeFormat.countdown(-30) == "0m")
    }
}
