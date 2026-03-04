import WidgetKit
import SwiftUI

struct NotificationWidget: Widget {
    let kind: String = "NotificationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotificationProvider()) { entry in
            NotificationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Мэдэгдэл")
        .description("Уншаагүй мэдэгдлүүдийг харах")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct NotificationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotificationEntry {
        NotificationEntry(
            date: Date(),
            unreadCount: 3,
            totalCount: 5,
            notifications: [
                NotificationItem(title: "Шинэ даалгавар", body: "Таны хуваарьт шинэ даалгавар нэмэгдлээ", icon: "📋", time: "одоо"),
                NotificationItem(title: "Даалгавар дууссан", body: "Даалгавар амжилттай дууслаа", icon: "✅", time: "5 мин"),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NotificationEntry) -> ()) {
        let entry = loadNotificationData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadNotificationData()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadNotificationData() -> NotificationEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.example.fsmapp")
        
        let unreadCount = userDefaults?.integer(forKey: "widget_notif_count") ?? 0
        let totalCount = userDefaults?.integer(forKey: "widget_notif_total") ?? 0
        
        var notifications: [NotificationItem] = []
        for i in 1...min(totalCount, 10) { // Limit to 10 notifications
            if let title = userDefaults?.string(forKey: "widget_notif\(i)_title"),
               let body = userDefaults?.string(forKey: "widget_notif\(i)_body") {
                let icon = userDefaults?.string(forKey: "widget_notif\(i)_icon") ?? "🔔"
                let time = userDefaults?.string(forKey: "widget_notif\(i)_time") ?? ""
                notifications.append(NotificationItem(title: title, body: body, icon: icon, time: time))
            }
        }
        
        return NotificationEntry(
            date: Date(),
            unreadCount: unreadCount,
            totalCount: totalCount,
            notifications: notifications
        )
    }
}

struct NotificationEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let totalCount: Int
    let notifications: [NotificationItem]
}

struct NotificationItem {
    let title: String
    let body: String
    let icon: String
    let time: String
}

struct NotificationWidgetEntryView: View {
    var entry: NotificationProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            NotificationWidgetMediumView(entry: entry)
        case .systemLarge:
            NotificationWidgetLargeView(entry: entry)
        default:
            NotificationWidgetMediumView(entry: entry)
        }
    }
}

struct NotificationWidgetMediumView: View {
    var entry: NotificationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Мэдэгдэл")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if entry.unreadCount > 0 {
                    Text("\(entry.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            // Notification list (first 3)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.notifications.prefix(3).enumerated()), id: \.offset) { index, notif in
                    NotificationRowView(notification: notif)
                }
            }
        }
        .padding()
    }
}

struct NotificationWidgetLargeView: View {
    var entry: NotificationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Мэдэгдэл")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if entry.unreadCount > 0 {
                    Text("\(entry.unreadCount) уншаагүй")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            Divider()
            
            // Notification list (up to 8)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.notifications.prefix(8).enumerated()), id: \.offset) { index, notif in
                    NotificationRowView(notification: notif)
                }
            }
        }
        .padding()
    }
}

struct NotificationRowView: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon
            Text(notification.icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(notification.time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
