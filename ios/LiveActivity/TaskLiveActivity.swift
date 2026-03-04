import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
struct TaskLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var taskCode: String
        var taskTitle: String
        var elapsedTime: String // "00:15:23"
        var progress: Int // 0-100
        var status: String // "Явагдаж буй"
    }
    
    var taskId: String
    var taskCode: String
    var taskTitle: String
}

// MARK: - Live Activity Widget
@available(iOS 16.1, *)
struct TaskLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskLiveActivityAttributes.self) { context in
            // Lock screen / Dynamic Island compact view
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region when tapped
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Явц")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.taskCode)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.status)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.progress)%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Text(context.state.taskTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Label(context.state.elapsedTime, systemImage: "clock")
                                .font(.caption)
                            ProgressView(value: Double(context.state.progress), total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .frame(width: 100)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Additional content if needed
                    HStack {
                        Text("Даралт: Дуусгах")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                // Compact leading (left side of Dynamic Island)
                Image(systemName: "checklist")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island)
                Text(context.state.elapsedTime)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            } minimal: {
                // Minimal view (when multiple activities)
                Image(systemName: "checklist")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TaskLiveActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "checklist")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Явц: \(context.state.taskCode)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text(context.state.taskTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text(context.state.elapsedTime)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("\(context.state.progress)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.1))
    }
}

// MARK: - Widget Bundle
@available(iOS 16.1, *)
@main
struct TaskLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        TaskLiveActivityWidget()
    }
}
