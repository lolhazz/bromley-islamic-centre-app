import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alerts: AlertSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                    if let until = alerts.coveredUntil {
                        Text("Alerts are set up until \(until.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB")))). They work without a connection, top up in the background and whenever you open the app, and we remind you before they run out.")
                    } else {
                        Text("Alerts are scheduled on your phone and work without a connection.")
                    }
                }
                Section {
                    Toggle("10 minutes before jama’ah", isOn: Binding(
                        get: { alerts.iqamahReminder },
                        set: { v in Task { await alerts.setIqamah(v) } }))
                    Toggle("Ramadan: imsak and iftar", isOn: Binding(
                        get: { alerts.ramadanAlerts },
                        set: { v in Task { await alerts.setRamadan(v) } }))
                } header: {
                    Text("Reminders")
                }
                if alerts.permissionDenied {
                    Section {
                        Label("Notifications are turned off for this app.", systemImage: "bell.slash")
                        Link("Open Settings", destination: URL(string: "app-settings:")!)
                    } footer: {
                        Text("Turn on notifications in Settings to receive prayer alerts.")
                    }
                }
                Section {
                    Text("Adhan times are calculated for Bromley. Congregational times can differ. Confirm the venue and jama’ah time before you travel.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .font(.body(17))
            .navigationTitle("Prayer alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
