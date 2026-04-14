import SwiftUI
import WidgetKit

struct WeatherPlaceholderEntry: TimelineEntry {
    let date: Date
}

struct WeatherPlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherPlaceholderEntry {
        WeatherPlaceholderEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherPlaceholderEntry) -> Void) {
        completion(WeatherPlaceholderEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherPlaceholderEntry>) -> Void) {
        let entry = WeatherPlaceholderEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct WeatherPlaceholderWidget: Widget {
    let kind: String = "WeatherPlaceholderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherPlaceholderProvider()) { _ in
            WeatherPlaceholderEntryView()
        }
        .configurationDisplayName("Weather")
        .description("Placeholder — forecast timeline next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WeatherPlaceholderEntryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weather")
                .font(.headline.weight(.semibold))
            Text("Widget wiring")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}
