import Foundation

struct PlannedAlert: Equatable {
    let id: String
    let date: Date
    let title: String
    let body: String
}

struct AlertPlan {
    /// Alerts in time order, followed by the "alerts are about to pause" reminder.
    let alerts: [PlannedAlert]
    /// Date of the last real prayer alert that fits. nil when nothing is switched on.
    let coveredUntil: Date?
}

/// Decides which local notifications to schedule.
/// iOS keeps at most 64 pending local notifications, so this fills the available slots in time order
/// (the more alerts a person turns on, the fewer days ahead fit) and adds a reminder shortly before they run out.
enum AlertPlanner {
    static let maxPending = 64
    static let searchDays = 90
    static let nudgeID = "alerts-pausing"

    static func plan(from now: Date,
                     enabled: Set<Prayer>,
                     iqamahReminder: Bool,
                     ramadanAlerts: Bool,
                     ramadanOverride: String?) -> AlertPlan {
        guard !enabled.isEmpty || ramadanAlerts else { return AlertPlan(alerts: [], coveredUntil: nil) }

        var candidates: [PlannedAlert] = []
        var day = now
        for _ in 0..<searchDays {
            let s = PrayerCalculator.schedule(for: day)
            if ramadanAlerts, Ramadan.isDuring(day, override: ramadanOverride) {
                let fajr = s.entries[0].adhan, maghrib = s.entries[3].adhan
                let imsak = fajr.addingTimeInterval(-Double(Ramadan.imsakMinutesBeforeFajr) * 60)
                candidates.append(PlannedAlert(id: "imsak-\(Int(imsak.timeIntervalSince1970))", date: imsak,
                                               title: "Imsak", body: "Suhoor ends. Fajr adhan \(TimeFormat.clock(fajr))"))
                candidates.append(PlannedAlert(id: "iftar-\(Int(maghrib.timeIntervalSince1970))", date: maghrib,
                                               title: "Iftar time", body: "Maghrib adhan \(TimeFormat.clock(maghrib))"))
            }
            for e in s.entries where enabled.contains(e.prayer) {
                candidates.append(PlannedAlert(id: "adhan-\(e.prayer.rawValue)-\(Int(e.adhan.timeIntervalSince1970))", date: e.adhan,
                                               title: "\(e.prayer.rawValue) time",
                                               body: "Adhan \(TimeFormat.clock(e.adhan)) · Iqamah \(TimeFormat.clock(e.iqamah))"))
                if iqamahReminder {
                    let warn = e.iqamah.addingTimeInterval(-10 * 60)
                    candidates.append(PlannedAlert(id: "iq-\(e.prayer.rawValue)-\(Int(e.adhan.timeIntervalSince1970))", date: warn,
                                                   title: "\(e.prayer.rawValue) jama’ah in 10 minutes",
                                                   body: "Iqamah \(TimeFormat.clock(e.iqamah))"))
                }
            }
            day = PrayerCalculator.tomorrow(after: s.date)
        }

        let upcoming = candidates.filter { $0.date > now }.sorted { $0.date < $1.date }
        var kept = Array(upcoming.prefix(maxPending - 1))      // one slot is kept for the reminder
        guard let last = kept.last else { return AlertPlan(alerts: [], coveredUntil: nil) }

        let nudgeDate = max(now.addingTimeInterval(60 * 60), last.date.addingTimeInterval(-24 * 60 * 60))
        if nudgeDate < last.date {
            kept.append(PlannedAlert(id: nudgeID, date: nudgeDate, title: "Prayer alerts are about to pause",
                                     body: "Open Bromley IC to keep your prayer alerts going."))
        }
        return AlertPlan(alerts: kept, coveredUntil: last.date)
    }
}
