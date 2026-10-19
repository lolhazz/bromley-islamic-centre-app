import SwiftUI

@main
struct BromleyApp: App {
    @StateObject private var alerts = AlertSettings()
    @StateObject private var config = ConfigStore()
    @Environment(\.scenePhase) private var phase
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
                .onChange(of: phase) { _, new in if new == .active { Task { await sync() } } }
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
