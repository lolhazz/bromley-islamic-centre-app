import SwiftUI

@main
struct BromleyApp: App {
    @StateObject private var alerts = AlertSettings()
    @StateObject private var config = ConfigStore()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(alerts)
                .environmentObject(config)
                .tint(Theme.gold)
                .task { alerts.reschedule(); await config.refresh() }
                .onChange(of: phase) { _, new in if new == .active { Task { await config.refresh() } } }
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
        .toolbarBackground(Theme.tealDeep, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
