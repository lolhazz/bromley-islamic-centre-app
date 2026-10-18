import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Prayer calculation")
struct PrayerCalculatorTests {
    /// Values shown on bromleyislamiccentre.org.uk on Wed 14 Oct 2026 (BST).
    @Test func matchesCentreWebsiteOn14Oct2026() {
        let day = PrayerCalculator.schedule(for: TestClock.date(2026, 10, 14))
        let times = Dictionary(uniqueKeysWithValues: day.entries.map { ($0.prayer, TestClock.hm($0.adhan)) })
        #expect(times[.fajr] == "05:50")
        #expect(times[.dhuhr] == "12:46")
        #expect(times[.asr] == "15:33")
        #expect(times[.maghrib] == "18:09")
        #expect(times[.isha] == "19:32")
    }

    @Test func iqamahTimesMatchWebsite() {
        let day = PrayerCalculator.schedule(for: TestClock.date(2026, 10, 14))
        let iq = Dictionary(uniqueKeysWithValues: day.entries.map { ($0.prayer, TestClock.hm($0.iqamah)) })
        #expect(iq[.fajr] == "06:30")
        #expect(iq[.dhuhr] == "13:32")
        #expect(iq[.asr] == "16:00")
        #expect(iq[.maghrib] == "18:14")
        #expect(iq[.isha] == "20:03")
    }

    @Test func sunriseSitsBetweenFajrAndDhuhr() {
        let day = PrayerCalculator.schedule(for: TestClock.date(2026, 10, 14))
        #expect(day.sunrise > day.entries[0].adhan)
        #expect(day.sunrise < day.entries[1].adhan)
        #expect(TestClock.hm(day.sunrise) == "07:21")
    }

    /// Every day of 2026 and 2027 must be in order, finite, and fall on the right civil day (covers BST changes
    /// and the midsummer case where the sun barely dips below the Fajr angle at Bromley's latitude).
    @Test func everyDayOfTwoYearsIsOrderedAndOnTheRightDay() {
        var day = TestClock.date(2026, 1, 1)
        let end = TestClock.date(2028, 1, 1)
        while day < end {
            let s = PrayerCalculator.schedule(for: day)
            let a = s.entries.map(\.adhan)
            #expect(a == a.sorted(), "out of order on \(day)")
            for e in s.entries {
                #expect(e.adhan.timeIntervalSince1970.isFinite)
                #expect(TestClock.london.isDate(e.adhan, inSameDayAs: s.date), "\(e.prayer) wrong day on \(day)")
            }
            #expect(s.sunrise < s.entries[1].adhan)
            day = PrayerCalculator.tomorrow(after: s.date)
        }
    }

    @Test func clocksGoingBackKeepsTimesSensible() {
        // BST ends Sun 25 Oct 2026: Dhuhr goes from about 12:44 BST on Saturday to about 11:44 GMT on Monday.
        let sat = PrayerCalculator.schedule(for: TestClock.date(2026, 10, 24))
        let mon = PrayerCalculator.schedule(for: TestClock.date(2026, 10, 26))
        #expect(TestClock.hm(sat.entries[1].adhan) == "12:44")
        #expect(TestClock.hm(mon.entries[1].adhan) == "11:44")
    }

    @Test func midsummerAndMidwinterAreReasonable() {
        let summer = PrayerCalculator.schedule(for: TestClock.date(2026, 6, 21))
        let winter = PrayerCalculator.schedule(for: TestClock.date(2026, 12, 21))
        #expect(summer.entries[4].adhan.timeIntervalSince(summer.entries[3].adhan) > 60 * 60)   // Isha well after Maghrib
        #expect(TestClock.hm(summer.entries[3].adhan) > "20:30")
        #expect(TestClock.hm(winter.entries[3].adhan) < "16:30")
        #expect(TestClock.hm(winter.entries[0].adhan) > "05:30")
    }

    @Test func iqamahOffsetsAreAppliedToAdhan() {
        let e = PrayerEntry(prayer: .dhuhr, adhan: TestClock.date(2026, 10, 14, 12, 46))
        #expect(e.iqamah == TestClock.date(2026, 10, 14, 13, 32))
        #expect(Prayer.allCases.map(\.iqamahOffset) == [40, 46, 27, 5, 31])
    }
}
