import SwiftUI

@main
struct BromleyApp: App {
    @StateObject private var alerts = AlertSettings()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(alerts)
                .tint(Theme.gold)
                .task { alerts.reschedule() }
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
