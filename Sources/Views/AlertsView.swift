import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alerts: AlertSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Screen(title: "Prayer alerts") {
                Text("Get a notification at the adhan for the prayers you choose. Alerts are scheduled on your phone and work offline.")
                    .font(.body(15)).foregroundStyle(.white.opacity(0.8))
                VStack(spacing: 0) {
                    ForEach(Prayer.allCases) { p in
                        Toggle(p.rawValue, isOn: Binding(
                            get: { alerts.enabled.contains(p) },
                            set: { v in Task { await alerts.toggle(p, on: v) } }))
                            .font(.body(16, weight: .medium)).padding(.vertical, 12)
                        if p != .isha { Divider().overlay(.white.opacity(0.12)) }
                    }
                }
                .card()
                Toggle("Remind me 10 minutes before jama’ah", isOn: Binding(
                    get: { alerts.iqamahReminder },
                    set: { v in Task { await alerts.setIqamah(v) } }))
                    .font(.body(15, weight: .medium)).card()
                if alerts.permissionDenied {
                    Text("Notifications are turned off for this app. Enable them in Settings to receive alerts.")
                        .font(.body(14)).foregroundStyle(Theme.gold)
                }
                Text("Adhan times are calculated for Bromley. Congregational times can differ. Confirm the venue and jama’ah time before you travel.")
                    .font(.body(13)).foregroundStyle(.white.opacity(0.6))
            }
            .tint(Theme.gold)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
