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
    @State private var tab = DebugRoute.tab

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Prayer", systemImage: "clock") }.tag(0)
            QiblaView()
                .tabItem { Label("Qibla", systemImage: "location.north.line") }.tag(1)
            EventsView()
                .tabItem { Label("What’s on", systemImage: "calendar") }.tag(2)
            CentreView()
                .tabItem { Label("Centre", systemImage: "building.columns") }.tag(3)
        }
    }
}

/// Debug-only launch arguments to jump straight to a screen when checking the UI:
/// `-tab 3 -centre services` (tabs: 0 Prayer, 1 Qibla, 2 What's on, 3 Centre).
enum DebugRoute {
    static func value(after flag: String) -> String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: flag), i + 1 < args.count { return args[i + 1] }
        #endif
        return nil
    }
    static var tab: Int { value(after: "-tab").flatMap(Int.init) ?? 0 }

    /// Pretend it is another moment: `-today 2026-10-21` (10:00 London that day), then `-skyHour 17.2` sets the hour.
    static func now(_ real: Date) -> Date {
        #if DEBUG
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/London")!
        var day = real
        if let t = value(after: "-today") {
            let f = DateFormatter()
            f.calendar = cal; f.timeZone = cal.timeZone; f.dateFormat = "yyyy-MM-dd"
            if let d = f.date(from: t) { day = d.addingTimeInterval(10 * 3600) }
        }
        if let h = value(after: "-skyHour").flatMap(Double.init) {
            return cal.startOfDay(for: day).addingTimeInterval(h * 3600)
        }
        return day
        #else
        return real
        #endif
    }
}
