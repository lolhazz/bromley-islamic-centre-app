import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Prayer source: timetable and iqamah rules")
struct PrayerSourceTests {
    private func day(_ f: String, _ sr: String, _ d: String, _ a: String, _ m: String, _ i: String) -> PrayerTimetable.Day {
        .init(fajr: f, sunrise: sr, dhuhr: d, asr: a, maghrib: m, isha: i)
    }

    /// A few real days from the London Unified Prayer Timetable 2026 (23 Oct is in summer time, 25 Oct is the day the clocks go back).
    private var table: PrayerTimetable {
        PrayerTimetable(year: 2026, days: [
            "2026-10-23": day("06:00", "07:35", "12:50", "15:20", "17:54", "19:19"),
            "2026-10-25": day("05:04", "06:39", "11:50", "14:17", "16:50", "18:17"),
        ])
    }
    private func times(_ s: DaySchedule) -> [String] { s.entries.map { TestClock.hm($0.adhan) } }
    private func iqamahs(_ s: DaySchedule) -> [String] { s.entries.map { TestClock.hm($0.iqamah) } }

    @Test func timetableTimesAreUsedAsLondonClockTimes() throws {
        let s = try #require(table.schedule(for: TestClock.date(2026, 10, 23)))
        #expect(times(s) == ["06:00", "12:50", "15:20", "17:54", "19:19"])
        #expect(TestClock.hm(s.sunrise) == "07:35")
        // The usual gaps when no rule is set.
        #expect(iqamahs(s) == ["06:40", "13:36", "15:47", "17:59", "19:50"])
    }

    @Test func timetableSurvivesTheClockChangeDay() throws {
        let s = try #require(table.schedule(for: TestClock.date(2026, 10, 25)))
        #expect(times(s) == ["05:04", "11:50", "14:17", "16:50", "18:17"])
        // Fajr to Isha is 13h 13m of real time on a 25-hour day.
        #expect(abs(s.entries[4].adhan.timeIntervalSince(s.entries[0].adhan) - (13 * 3600 + 13 * 60)) < 1)
    }

    @Test func missingDayOrYearGivesNil() {
        #expect(table.schedule(for: TestClock.date(2026, 10, 24)) == nil)
        #expect(table.schedule(for: TestClock.date(2027, 10, 23)) == nil)
    }

    @Test func aBadTimeInTheTimetableGivesNilRatherThanAWrongTime() {
        let bad = PrayerTimetable(year: 2026, days: ["2026-10-23": day("6:00", "07:35", "12:50", "15:20", "17:54", "19:19")])
        #expect(bad.schedule(for: TestClock.date(2026, 10, 23)) == nil)
    }

    @Test func fallsBackToTheCalculatorWithoutATimetable() {
        let d = TestClock.date(2026, 10, 23)
        let s = PrayerSource.schedule(for: d, timetables: [:], rules: [:])
        let c = PrayerCalculator.calculate(for: d)
        #expect(zip(s.entries, c.entries).allSatisfy { $0.adhan == $1.adhan && $0.iqamah == $1.iqamah })
        // A year the app has no timetable for also falls back.
        let other = PrayerSource.schedule(for: TestClock.date(2027, 3, 1), timetables: [2026: table], rules: [:])
        #expect(other.entries[0].adhan == PrayerCalculator.calculate(for: TestClock.date(2027, 3, 1)).entries[0].adhan)
    }

    @Test func prefersTheTimetableOverTheCalculator() {
        let s = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: [:])
        #expect(times(s) == ["06:00", "12:50", "15:20", "17:54", "19:19"])
    }

    // MARK: Iqamah rules

    @Test func minutesAfterAdhanRule() {
        let rules = PrayerSource.parseRules(["fajr": .init(afterMinutes: 30), "isha": .init(afterMinutes: 15)])
        let s = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: rules)
        #expect(iqamahs(s) == ["06:30", "13:36", "15:47", "17:59", "19:34"])   // others keep the usual gaps
        #expect(times(s) == ["06:00", "12:50", "15:20", "17:54", "19:19"])     // adhan never moves
    }

    @Test func fixedTimeRule() {
        let rules = PrayerSource.parseRules(["dhuhr": .init(time: "13:30"), "asr": .init(time: "16:15")])
        let s = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: rules)
        #expect(TestClock.hm(s.entries[1].iqamah) == "13:30")
        #expect(TestClock.hm(s.entries[2].iqamah) == "16:15")
    }

    @Test func fixedTimeStaysAtLondonClockTimeAcrossTheClockChange() {
        let rules = PrayerSource.parseRules(["dhuhr": .init(time: "13:30")])
        let summer = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: rules)
        let winter = PrayerSource.schedule(for: TestClock.date(2026, 10, 25), timetables: [2026: table], rules: rules)
        #expect(TestClock.hm(summer.entries[1].iqamah) == "13:30")
        #expect(TestClock.hm(winter.entries[1].iqamah) == "13:30")
    }

    @Test func fixedTimeWinsWhenBothAreSet() {
        let rules = PrayerSource.parseRules(["fajr": .init(afterMinutes: 10, time: "06:45")])
        let s = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: rules)
        #expect(TestClock.hm(s.entries[0].iqamah) == "06:45")
    }

    @Test func unusableRulesFallBackToTheUsualGap() {
        let rules = PrayerSource.parseRules([
            "fajr": .init(time: "05:00"),          // before the 06:00 adhan
            "dhuhr": .init(afterMinutes: 500),     // out of range
            "asr": .init(time: "25:99"),           // not a time
            "maghrib": .init(),                    // empty
        ])
        let s = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: rules)
        #expect(iqamahs(s) == ["06:40", "13:36", "15:47", "17:59", "19:50"])
    }

    @Test func rulesApplyToCalculatedTimesToo() {
        let d = TestClock.date(2026, 10, 23)
        let rules = PrayerSource.parseRules(["fajr": .init(afterMinutes: 25)])
        let s = PrayerSource.schedule(for: d, timetables: [:], rules: rules)
        #expect(s.entries[0].iqamah == s.entries[0].adhan.addingTimeInterval(25 * 60))
    }

    @Test func unknownPrayerKeysAreIgnored() {
        #expect(PrayerSource.parseRules(["sunrise": .init(afterMinutes: 5), "Fajr": .init(afterMinutes: 5)]).isEmpty)
        #expect(PrayerSource.parseRules(nil).isEmpty)
    }

    @Test func zeroMinutesMeansIqamahAtTheAdhan() {
        let rules = PrayerSource.parseRules(["maghrib": .init(afterMinutes: 0)])
        let s = PrayerSource.schedule(for: TestClock.date(2026, 10, 23), timetables: [2026: table], rules: rules)
        #expect(s.entries[3].iqamah == s.entries[3].adhan)
    }

    // MARK: Decoding what the server sends

    @Test func decodesEditorIqamahJSON() throws {
        let json = #"{"iqamah":{"fajr":{"afterMinutes":30},"dhuhr":{"time":"13:30"}},"venueBanner":"x"}"#
        let c = try JSONDecoder().decode(RemoteConfig.self, from: Data(json.utf8))
        #expect(c.iqamah?["fajr"] == IqamahRule(afterMinutes: 30, time: nil))
        #expect(c.iqamah?["dhuhr"] == IqamahRule(afterMinutes: nil, time: "13:30"))
        #expect(try JSONDecoder().decode(RemoteConfig.self, from: Data("{}".utf8)).iqamah == nil)
    }

    private func fullYear(_ year: Int, mutate: (inout [String: PrayerTimetable.Day]) -> Void = { _ in }) -> Data {
        var days: [String: PrayerTimetable.Day] = [:]
        var d = TestClock.london.date(from: DateComponents(year: year, month: 1, day: 1))!
        while TestClock.london.component(.year, from: d) == year {
            let c = TestClock.london.dateComponents([.year, .month, .day], from: d)
            days[PrayerTimetable.key(c)] = day("05:14", "06:51", "11:49", "14:06", "16:37", "18:05")
            d = TestClock.london.date(byAdding: .day, value: 1, to: d)!
        }
        mutate(&days)
        return try! JSONEncoder().encode(PrayerTimetable(year: year, days: days))
    }

    @Test func acceptsAWholeYearAndRejectsAnythingElse() {
        #expect(PrayerFeed.decodeTimetable(fullYear(2026), year: 2026)?.days.count == 365)
        #expect(PrayerFeed.decodeTimetable(fullYear(2028), year: 2028)?.days.count == 366)
        #expect(PrayerFeed.decodeTimetable(fullYear(2026), year: 2027) == nil, "wrong year")
        #expect(PrayerFeed.decodeTimetable(fullYear(2026) { $0.removeValue(forKey: "2026-05-05") }, year: 2026) == nil, "missing day")
        #expect(PrayerFeed.decodeTimetable(fullYear(2026) { $0["2026-05-05"] = day("5am", "06:51", "11:49", "14:06", "16:37", "18:05") }, year: 2026) == nil, "bad time")
        #expect(PrayerFeed.decodeTimetable(Data("not json".utf8), year: 2026) == nil)
        #expect(PrayerFeed.decodeTimetable(Data(#"{"error":"nope"}"#.utf8), year: 2026) == nil)
    }

    @Test func fetchesNextYearOnceNovemberStarts() {
        #expect(PrayerFeed.yearsWanted(now: TestClock.date(2026, 10, 31)) == [2026])
        #expect(PrayerFeed.yearsWanted(now: TestClock.date(2026, 11, 1)) == [2026, 2027])
        #expect(PrayerFeed.yearsWanted(now: TestClock.date(2026, 12, 31)) == [2026, 2027])
        #expect(PrayerFeed.yearsWanted(now: TestClock.date(2027, 1, 1)) == [2027])
    }

    @Test func fetchTimingRules() {
        let now = TestClock.date(2026, 11, 1, 12, 0)
        let hour: TimeInterval = 3600
        #expect(PrayerFeed.shouldFetch(have: false, fetchedAt: nil, triedAt: nil, now: now), "nothing saved yet")
        #expect(!PrayerFeed.shouldFetch(have: true, fetchedAt: now - 2 * hour, triedAt: now - 2 * hour, now: now), "fresh copy")
        #expect(PrayerFeed.shouldFetch(have: true, fetchedAt: now - 25 * hour, triedAt: now - 25 * hour, now: now), "stale copy")
        #expect(!PrayerFeed.shouldFetch(have: false, fetchedAt: nil, triedAt: now - 0.5 * hour, now: now), "just failed")
        #expect(PrayerFeed.shouldFetch(have: false, fetchedAt: nil, triedAt: now - 2 * hour, now: now), "failure is retried later")
        #expect(!PrayerFeed.shouldFetch(have: true, fetchedAt: now - 30 * hour, triedAt: now - 0.5 * hour, now: now), "stale but just tried")
    }

    @Test func hourMinuteIsStrict() {
        #expect(IqamahRule.hourMinute("06:05")! == (6, 5))
        #expect(IqamahRule.hourMinute("23:59")! == (23, 59))
        for bad in ["6:05", "24:00", "12:60", "1230", "12:5", "ab:cd", "", "12:30:00"] { #expect(IqamahRule.hourMinute(bad) == nil, "\(bad)") }
    }
}
