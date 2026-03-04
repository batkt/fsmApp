import Flutter
import UIKit
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up widget update channel
    let controller = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(
      name: "com.example.fsmapp/widget",
      binaryMessenger: controller.binaryMessenger
    )
    
    // Set up live activity channel for Dynamic Island
    let liveActivityChannel = FlutterMethodChannel(
      name: "com.example.fsmapp/live_activity",
      binaryMessenger: controller.binaryMessenger
    )
    
    widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "updateWidget":
        // Reload widget timelines (data already written to App Group via writeToAppGroup)
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
          WidgetCenter.shared.reloadTimelines(ofKind: "NotificationWidget")
        }
        result(true)
      case "updateNotificationWidget":
        // Reload widget timelines (data already written to App Group via writeToAppGroup)
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadTimelines(ofKind: "NotificationWidget")
        }
        result(true)
      case "writeToAppGroup":
        // Write SharedPreferences data to App Group UserDefaults
        if let args = call.arguments as? [String: Any],
           let data = args["data"] as? [String: Any] {
          self.writeToAppGroup(data: data)
          result(true)
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Live Activity (Dynamic Island) handler
    // Note: Full implementation requires Activity Extension target
    // See ios/LiveActivity/DYNAMIC_ISLAND_SETUP.md for setup instructions
    if #available(iOS 16.1, *) {
      liveActivityChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "startTaskActivity":
          if let args = call.arguments as? [String: Any],
             let taskId = args["taskId"] as? String,
             let taskCode = args["taskCode"] as? String,
             let taskTitle = args["taskTitle"] as? String {
            let elapsedTime = args["elapsedTime"] as? String ?? "00:00:00"
            let progress = args["progress"] as? Int ?? 0
            let status = args["status"] as? String ?? "Явагдаж буй"
            
            #if canImport(ActivityKit)
            LiveActivityManager.shared.startTaskActivity(
              taskId: taskId,
              taskCode: taskCode,
              taskTitle: taskTitle,
              elapsedTime: elapsedTime,
              progress: progress,
              status: status
            )
            #endif
            
            result(true)
          } else {
            result(false)
          }
        case "updateTaskActivity":
          if let args = call.arguments as? [String: Any],
             let elapsedTime = args["elapsedTime"] as? String,
             let progress = args["progress"] as? Int {
            let status = args["status"] as? String
            
            #if canImport(ActivityKit)
            LiveActivityManager.shared.updateTaskActivity(
              elapsedTime: elapsedTime,
              progress: progress,
              status: status
            )
            #endif
            
            result(true)
          } else {
            result(false)
          }
        case "endTaskActivity":
          #if canImport(ActivityKit)
          LiveActivityManager.shared.endTaskActivity()
          #endif
          result(true)
        case "isAvailable":
          // Check if Live Activities are available
          #if canImport(ActivityKit)
          result(ActivityAuthorizationInfo().areActivitiesEnabled)
          #else
          result(false)
          #endif
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func writeToAppGroup(data: [String: Any]) {
    guard let userDefaults = UserDefaults(suiteName: "group.com.example.fsmapp") else {
      print("[AppDelegate] Failed to access App Group UserDefaults")
      return
    }
    
    // Write all widget data to App Group
    for (key, value) in data {
      if let intValue = value as? Int {
        userDefaults.set(intValue, forKey: key)
      } else if let stringValue = value as? String {
        userDefaults.set(stringValue, forKey: key)
      } else if let boolValue = value as? Bool {
        userDefaults.set(boolValue, forKey: key)
      } else if let doubleValue = value as? Double {
        userDefaults.set(doubleValue, forKey: key)
      }
    }
    
    userDefaults.synchronize()
  }
}
import Foundation
import ActivityKit
import WidgetKit

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    // Start a Live Activity for task tracking
    func startTaskActivity(
        taskId: String,
        taskCode: String,
        taskTitle: String,
        elapsedTime: String = "00:00:00",
        progress: Int = 0,
        status: String = "Явагдаж буй"
    ) {
        // End any existing activity
        endTaskActivity()
        
        let attributes = TaskLiveActivityAttributes(
            taskId: taskId,
            taskCode: taskCode,
            taskTitle: taskTitle
        )
        
        let initialState = TaskLiveActivityAttributes.ContentState(
            taskCode: taskCode,
            taskTitle: taskTitle,
            elapsedTime: elapsedTime,
            progress: progress,
            status: status
        )
        
        do {
            let activity = try Activity<TaskLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil // Use pushType: .token for server-driven updates
            )
            print("[LiveActivity] Started activity: \(activity.id)")
        } catch {
            print("[LiveActivity] Failed to start activity: \(error)")
        }
    }
    
    // Update existing Live Activity
    func updateTaskActivity(
        elapsedTime: String,
        progress: Int,
        status: String? = nil
    ) {
        guard let activity = Activity<TaskLiveActivityAttributes>.activities.first else {
            return
        }
        
        let updatedState = TaskLiveActivityAttributes.ContentState(
            taskCode: activity.attributes.taskCode,
            taskTitle: activity.attributes.taskTitle,
            elapsedTime: elapsedTime,
            progress: progress,
            status: status ?? activity.contentState.status
        )
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    // End Live Activity
    func endTaskActivity() {
        for activity in Activity<TaskLiveActivityAttributes>.activities {
            let finalState = TaskLiveActivityAttributes.ContentState(
                taskCode: activity.attributes.taskCode,
                taskTitle: activity.attributes.taskTitle,
                elapsedTime: activity.contentState.elapsedTime,
                progress: 100,
                status: "Дууссан"
            )
            
            Task {
                await activity.end(using: finalState, dismissalPolicy: .immediate)
            }
        }
    }
    
    // Check if Live Activities are available
    static func isAvailable() -> Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
}
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
struct TaskLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        TaskLiveActivityWidget()
    }
}
