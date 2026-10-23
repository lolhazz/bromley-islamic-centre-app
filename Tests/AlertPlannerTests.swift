import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Alert planner")
struct AlertPlannerTests {
    private let now = TestClock.date(2026, 10, 23, 12, 0)
    private func plan(_ enabled: Set<Prayer>, iqamah: Bool = false, ramadan: Bool = false, from: Date? = nil) -> AlertPlan {
        AlertPlanner.plan(from: from ?? now, enabled: enabled, iqamahReminder: iqamah, ramadanAlerts: ramadan, ramadanOverride: nil)
    }

    @Test func nothingSwitchedOnSchedulesNothing() {
        let p = plan([])
        #expect(p.alerts.isEmpty && p.coveredUntil == nil)
    }

    @Test func neverExceedsTheSystemLimit() {
        let p = plan(Set(Prayer.allCases), iqamah: true, ramadan: true)
        #expect(p.alerts.count <= AlertPlanner.maxPending)
        #expect(Set(p.alerts.map(\.id)).count == p.alerts.count)
    }

    @Test func alertsAreFutureAndInTimeOrderExceptTheReminder() {
        let p = plan(Set(Prayer.allCases), iqamah: true)
        #expect(p.alerts.allSatisfy { $0.date > now })
        let real = p.alerts.filter { $0.id != AlertPlanner.nudgeID }
        #expect(real.map(\.date) == real.map(\.date).sorted())
    }

    @Test func allFiveAdhansCoverAboutTwoWeeks() throws {
        let p = plan(Set(Prayer.allCases))
        let days = try #require(p.coveredUntil).timeIntervalSince(now) / 86_400
        #expect(days > 11 && days < 13.5)
    }

    @Test func fewerAlertsReachFurther() throws {
        let one = try #require(plan([.fajr]).coveredUntil).timeIntervalSince(now) / 86_400
        let all = try #require(plan(Set(Prayer.allCases), iqamah: true).coveredUntil).timeIntervalSince(now) / 86_400
        #expect(one > 55)
        #expect(all > 5 && all < 7.5)
        #expect(one > all * 5)
    }

    @Test func reminderComesOneDayBeforeTheLastAlert() throws {
        let p = plan(Set(Prayer.allCases), iqamah: true)
        let nudge = try #require(p.alerts.first { $0.id == AlertPlanner.nudgeID })
        let last = try #require(p.coveredUntil)
        #expect(abs(last.timeIntervalSince(nudge.date) - 86_400) < 1)
        #expect(nudge.title.contains("pause"))
    }

    @Test func iqamahReminderIsTenMinutesBeforeJamaah() throws {
        let p = plan([.dhuhr], iqamah: true)
        let reminder = try #require(p.alerts.first { $0.id.hasPrefix("iq-Dhuhr") })
        let day = PrayerCalculator.schedule(for: reminder.date)
        let dhuhr = day.entries.first { $0.prayer == .dhuhr }!
        #expect(abs(dhuhr.iqamah.timeIntervalSince(reminder.date) - 600) < 1)
    }

    @Test func ramadanAlertsAppearOnlyDuringRamadan() {
        let before = plan([], ramadan: true, from: TestClock.date(2027, 2, 1, 12))      // Ramadan starts 8 Feb
        let imsaks = before.alerts.filter { $0.title == "Imsak" }
        #expect(!imsaks.isEmpty)
        #expect(imsaks.allSatisfy { $0.date >= TestClock.date(2027, 2, 8, 0) })
        #expect(plan([], ramadan: true).alerts.isEmpty)                                     // nothing near Ramadan in October
    }

    @Test func switchingOffRemovesEverything() {
        #expect(plan([.fajr]).alerts.isEmpty == false)
        #expect(plan([]).alerts.isEmpty)
    }
}
