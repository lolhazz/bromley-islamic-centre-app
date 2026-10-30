import Testing
import Foundation
@testable import BromleyIslamicCentre

@Suite("Event dates")
struct EventDateTests {
    @Test func readsDateAndTime() {
        let p = EventDate.parse("Fri 23 Oct 2026 · 1:15 pm")
        #expect(p?.hasTime == true)
        #expect(p.map { TestClock.hm($0.date) } == "13:15")
        #expect(p.map { TestClock.london.component(.day, from: $0.date) } == 23)
    }

    @Test func readsDateWithoutTimeAndFullMonthNames() {
        let p = EventDate.parse("Saturday 7 November 2026")
        #expect(p?.hasTime == false)
        #expect(p.map { TestClock.london.component(.month, from: $0.date) } == 11)
        #expect(EventDate.parse("1 Dec 2026, 12:00 am").map { TestClock.hm($0.date) } == "00:00")
        #expect(EventDate.parse("1 Dec 2026 12 pm").map { TestClock.hm($0.date) } == "12:00")
    }

    @Test func recurringOrUnreadableTextHasNoDate() {
        #expect(EventDate.parse("Sundays · registration 2:45 pm · finish 5:00 pm") == nil)
        #expect(EventDate.parse("To be announced") == nil)
        #expect(EventDate.parse("31 Feb 2026") == nil)
        #expect(EventDate.parse(nil) == nil)
        #expect(!EventDate.isOver("Sundays · 2:45 pm", now: TestClock.date(2030, 1, 1)))
        #expect(EventDate.countdown("Sundays · 2:45 pm", now: TestClock.date(2026, 10, 25)) == nil)
    }

    @Test func overMeansTimePassedOrDayPassed() {
        let w = "Fri 23 Oct 2026 · 1:15 pm"
        #expect(!EventDate.isOver(w, now: TestClock.date(2026, 10, 23, 13, 0)))
        #expect(EventDate.isOver(w, now: TestClock.date(2026, 10, 23, 13, 30)))
        #expect(!EventDate.isOver("23 Oct 2026", now: TestClock.date(2026, 10, 23, 22, 0)))
        #expect(EventDate.isOver("23 Oct 2026", now: TestClock.date(2026, 10, 24, 0, 5)))
    }

    @Test func countdownWords() {
        let now = TestClock.date(2026, 10, 25, 16, 0)
        #expect(EventDate.countdown("25 Oct 2026 · 8:00 pm", now: now) == "Today")
        #expect(EventDate.countdown("26 Oct 2026", now: now) == "Tomorrow")
        #expect(EventDate.countdown("30 Oct 2026", now: now) == "In 5 days")
        #expect(EventDate.countdown("22 Nov 2026", now: now) == "In 4 weeks")
        #expect(EventDate.countdown("24 Oct 2026", now: now) == nil)
    }

    /// Clocks go back on 25 Oct 2026 (a 25-hour day): the next day must still be "Tomorrow".
    @Test func dayCountSurvivesClockChange() {
        #expect(EventDate.countdown("26 Oct 2026", now: TestClock.date(2026, 10, 25, 9, 0)) == "Tomorrow")
        #expect(EventDate.countdown("25 Oct 2026 · 11:00 pm", now: TestClock.date(2026, 10, 24, 9, 0)) == "Tomorrow")
    }
}
