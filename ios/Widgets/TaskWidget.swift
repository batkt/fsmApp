import WidgetKit
import SwiftUI

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            TaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Даалгаврууд")
        .description("Өнөөдрийн даалгавруудыг харах")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            totalTasks: 5,
            completedTasks: 2,
            tasks: [
                TaskItem(title: "Даалгавар 1", time: "09:00 - 10:00", status: 0),
                TaskItem(title: "Даалгавар 2", time: "10:00 - 11:00", status: 1),
                TaskItem(title: "Даалгавар 3", time: "11:00 - 12:00", status: 2),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let entry = loadTaskData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadTaskData()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadTaskData() -> TaskEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.batkt.workease")
        
        let totalTasks = userDefaults?.integer(forKey: "widget_total_tasks") ?? 0
        let completedTasks = userDefaults?.integer(forKey: "widget_completed_tasks") ?? 0
        
        var tasks: [TaskItem] = []
        for i in 1...min(totalTasks, 10) { // Limit to 10 tasks for widget
            if let title = userDefaults?.string(forKey: "widget_task\(i)_title"),
               let time = userDefaults?.string(forKey: "widget_task\(i)_time"),
               title != "—" {
                let status = userDefaults?.integer(forKey: "widget_task\(i)_status") ?? 0
                tasks.append(TaskItem(title: title, time: time, status: status))
            }
        }
        
        return TaskEntry(
            date: Date(),
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            tasks: tasks
        )
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let totalTasks: Int
    let completedTasks: Int
    let tasks: [TaskItem]
}

struct TaskItem {
    let title: String
    let time: String
    let status: Int // 0=pending, 1=inProgress, 2=completed, 3=overdue
}

struct TaskWidgetEntryView: View {
    var entry: TaskProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            TaskWidgetMediumView(entry: entry)
        case .systemLarge:
            TaskWidgetLargeView(entry: entry)
        default:
            TaskWidgetMediumView(entry: entry)
        }
    }
}

struct TaskWidgetMediumView: View {
    var entry: TaskEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Өнөөдрийн даалгавар")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress
            HStack {
                Text("\(entry.completedTasks)/\(entry.totalTasks)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Spacer()
                ProgressView(value: entry.totalTasks > 0 ? Double(entry.completedTasks) / Double(entry.totalTasks) : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            
            // Task list (first 3)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entry.tasks.prefix(3).enumerated()), id: \.offset) { index, task in
                    TaskRowView(task: task)
                }
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (EEE)"
        formatter.locale = Locale(identifier: "mn_MN")
        return formatter.string(from: date)
    }
}

struct TaskWidgetLargeView: View {
    var entry: TaskEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Өнөөдрийн даалгавар")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatDate(entry.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Явц: \(entry.completedTasks)/\(entry.totalTasks)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                ProgressView(value: entry.totalTasks > 0 ? Double(entry.completedTasks) / Double(entry.totalTasks) : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(height: 8)
            }
            
            Divider()
            
            // Task list (up to 8)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.tasks.prefix(8).enumerated()), id: \.offset) { index, task in
                    TaskRowView(task: task)
                }
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (EEE)"
        formatter.locale = Locale(identifier: "mn_MN")
        return formatter.string(from: date)
    }
}

struct TaskRowView: View {
    let task: TaskItem
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(task.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status badge
            Text(statusText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor)
                .cornerRadius(4)
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case 0: return .orange // pending
        case 1: return .blue // inProgress
        case 2: return .green // completed
        case 3: return .red // overdue
        default: return .gray
        }
    }
    
    private var statusText: String {
        switch task.status {
        case 0: return "Хүлээгдэж"
        case 1: return "Явагдаж"
        case 2: return "Дууссан"
        case 3: return "Хэтэрсэн"
        default: return ""
        }
    }
}

@main
struct TaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
        NotificationWidget()
    }
}
