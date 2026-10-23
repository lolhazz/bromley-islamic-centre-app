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

    /// How far ahead alerts are currently set up. nil when none are scheduled.
    @Published private(set) var coveredUntil: Date?

    /// Replaces all pending notifications with a fresh plan. Safe to call as often as needed.
    func reschedule(now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let plan = AlertPlanner.plan(from: now, enabled: enabled, iqamahReminder: iqamahReminder,
                                     ramadanAlerts: ramadanAlerts, ramadanOverride: ramadanOverride)
        coveredUntil = plan.coveredUntil
        for a in plan.alerts { add(center, a) }
    }

    private static let london = TimeZone(identifier: "Europe/London")!

    private func add(_ c: UNUserNotificationCenter, _ a: PlannedAlert) {
        let content = UNMutableNotificationContent()
        content.title = a.title; content.body = a.body; content.sound = .default
        // Fire at London clock time even if the phone is in another time zone.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Self.london
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: a.date)
        comps.timeZone = Self.london
        c.add(UNNotificationRequest(identifier: a.id, content: content,
                                    trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
    }
}
