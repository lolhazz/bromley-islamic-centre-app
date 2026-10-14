import Foundation
import UserNotifications

@MainActor
final class AlertSettings: ObservableObject {
    @Published var enabled: Set<Prayer> { didSet { save(); reschedule() } }
    @Published var iqamahReminder: Bool { didSet { save(); reschedule() } }
    @Published var ramadanAlerts: Bool { didSet { save(); reschedule() } }
    @Published var permissionDenied = false
    var ramadanOverride: String?

    private let key = "alertPrayers", iqKey = "iqamahReminder", ramKey = "ramadanAlerts"

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        enabled = Set(saved.compactMap(Prayer.init(rawValue:)))
        iqamahReminder = UserDefaults.standard.bool(forKey: iqKey)
        ramadanAlerts = UserDefaults.standard.bool(forKey: ramKey)
    }

    private func save() {
        UserDefaults.standard.set(enabled.map(\.rawValue), forKey: key)
        UserDefaults.standard.set(iqamahReminder, forKey: iqKey)
        UserDefaults.standard.set(ramadanAlerts, forKey: ramKey)
    }

    func toggle(_ p: Prayer, on: Bool) async {
        if on, !(await requestPermission()) { return }
        if on { enabled.insert(p) } else { enabled.remove(p) }
    }

    func setIqamah(_ on: Bool) async {
        if on, !(await requestPermission()) { return }
        iqamahReminder = on
    }

    func setRamadan(_ on: Bool) async {
        if on, !(await requestPermission()) { return }
        ramadanAlerts = on
    }

    private func requestPermission() async -> Bool {
        let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        permissionDenied = !ok
        return ok
    }

    /// Schedules the next 7 days of alerts (stays inside iOS's 64 pending-notification cap).
    func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !enabled.isEmpty || ramadanAlerts else { return }
        var day = Date()
        var remaining = 60
        for _ in 0..<7 {
            let s = PrayerCalculator.schedule(for: day)
            if ramadanAlerts, Ramadan.isDuring(day, override: ramadanOverride) {
                let imsak = s.entries[0].adhan.addingTimeInterval(-Double(Ramadan.imsakMinutesBeforeFajr) * 60)
                if imsak > Date(), remaining > 0 {
                    add(center, id: "imsak-\(imsak.timeIntervalSince1970)", date: imsak,
                        title: "Imsak", body: "Suhoor ends. Fajr adhan \(TimeFormat.clock(s.entries[0].adhan))")
                    remaining -= 1
                }
                let iftar = s.entries[3].adhan
                if iftar > Date(), remaining > 0 {
                    add(center, id: "iftar-\(iftar.timeIntervalSince1970)", date: iftar,
                        title: "Iftar time", body: "Maghrib adhan \(TimeFormat.clock(iftar))")
                    remaining -= 1
                }
            }
            for e in s.entries where enabled.contains(e.prayer) {
                if remaining <= 0 { break }
                if e.adhan > Date() {
                    add(center, id: "adhan-\(e.prayer.rawValue)-\(e.adhan.timeIntervalSince1970)", date: e.adhan,
                        title: "\(e.prayer.rawValue) time", body: "Adhan \(TimeFormat.clock(e.adhan)) · Iqamah \(TimeFormat.clock(e.iqamah))")
                    remaining -= 1
                }
                let warn = e.iqamah.addingTimeInterval(-10 * 60)
                if iqamahReminder, warn > Date(), remaining > 0 {
                    add(center, id: "iq-\(e.prayer.rawValue)-\(e.adhan.timeIntervalSince1970)", date: warn,
                        title: "\(e.prayer.rawValue) jama’ah in 10 minutes", body: "Iqamah \(TimeFormat.clock(e.iqamah))")
                    remaining -= 1
                }
            }
            day = PrayerCalculator.tomorrow(after: s.date)
        }
    }

    private func add(_ c: UNUserNotificationCenter, id: String, date: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        c.add(UNNotificationRequest(identifier: id, content: content,
                                    trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
    }
}
