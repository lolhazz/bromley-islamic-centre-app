import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alerts: AlertSettings

    private var coverage: String {
        guard let until = alerts.coveredUntil else {
            return "Alerts are scheduled on your phone and work without a connection."
        }
        let day = until.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB")))
        return "Alerts are set up until \(day). They work without a connection, top up in the background and whenever you open the app, and we remind you before they run out."
    }

    var body: some View {
        Form {
            Section {
                ForEach(Prayer.allCases) { p in
                    Toggle(p.rawValue, isOn: Binding(
                        get: { alerts.enabled.contains(p) },
                        set: { v in Task { await alerts.toggle(p, on: v) } }))
                }
            } header: {
                Text("Notify me at the adhan")
            } footer: {
                Text(coverage)
            }
            .listRowBackground(Theme.surface)

            Section {
                Toggle("10 minutes before jama’ah", isOn: Binding(
                    get: { alerts.iqamahReminder },
                    set: { v in Task { await alerts.setIqamah(v) } }))
                Toggle("Ramadan: imsak and iftar", isOn: Binding(
                    get: { alerts.ramadanAlerts },
                    set: { v in Task { await alerts.setRamadan(v) } }))
            } header: {
                Text("Reminders")
            } footer: {
                Text("Adhan times are calculated for Bromley. Congregational times can differ, so confirm the venue and jama’ah time before you travel.")
            }
            .listRowBackground(Theme.surface)

            if alerts.permissionDenied {
                Section {
                    Text("Notifications are turned off for this app.")
                    Link("Open Settings", destination: URL(string: "app-settings:")!)
                } footer: {
                    Text("Turn on notifications in Settings to receive prayer alerts.")
                }
                .listRowBackground(Theme.surface)
            }
        }
        .font(.body(17))
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Prayer alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
