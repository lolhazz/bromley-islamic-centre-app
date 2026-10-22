import WidgetKit
import SwiftUI

struct PrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BromleyPrayerWidget", provider: PrayerProvider()) { entry in
            PrayerWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Next prayer")
        .description("Countdown to the next adhan or jama’ah at Bromley Islamic Centre. Times are calculated for Bromley.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct BromleyWidgetBundle: WidgetBundle {
    var body: some Widget { PrayerWidget() }
}
