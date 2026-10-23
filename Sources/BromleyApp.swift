import SwiftUI
import BackgroundTasks

@main
struct BromleyApp: App {
    @StateObject private var alerts = AlertSettings()
    @StateObject private var config = ConfigStore()
    @Environment(\.scenePhase) private var phase

    /// Identifier of the daily background refresh that tops up prayer alerts (also listed in Info.plist).
    static let refreshID = "uk.org.bromleyislamiccentre.app.refresh"

    private func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func sync() async {
        alerts.ramadanOverride = config.ramadanStart
        alerts.reschedule()
        await config.refresh()
        alerts.ramadanOverride = config.ramadanStart
        alerts.reschedule()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(alerts)
                .environmentObject(config)
                .tint(Theme.accent)
                .task { await sync() }
                .onChange(of: phase) { _, new in
                    if new == .active { Task { await sync() } }
                    if new == .background { scheduleRefresh() }
                }
        }
        .backgroundTask(.appRefresh(Self.refreshID)) {
            await sync()
            await scheduleRefresh()
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Prayer", systemImage: "clock") }
            QiblaView()
                .tabItem { Label("Qibla", systemImage: "location.north.line") }
            EventsView()
                .tabItem { Label("What’s on", systemImage: "calendar") }
            CentreView()
                .tabItem { Label("Centre", systemImage: "building.columns") }
        }
    }
}
