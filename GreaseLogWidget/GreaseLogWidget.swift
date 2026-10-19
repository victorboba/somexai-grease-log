import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: WidgetSnapshot.load())
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct GreaseLogWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppConfig.appName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(entry.snapshot.entriesThisWeek)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("this week")
                .font(.caption)
                .foregroundStyle(.secondary)
            if family != .systemSmall, let title = entry.snapshot.lastEntryTitle, let date = entry.snapshot.lastEntryDate {
                Divider()
                Text("Last: \(title.isEmpty ? AppConfig.entryNoun : title)")
                    .font(.footnote)
                    .lineLimit(1)
                Text(date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct GreaseLogWidget: Widget {
    let kind = "GreaseLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            GreaseLogWidgetView(entry: entry)
        }
        .configurationDisplayName(AppConfig.appName)
        .description("\(AppConfig.entryNounPlural) this week and your latest one.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct GreaseLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        GreaseLogWidget()
    }
}
