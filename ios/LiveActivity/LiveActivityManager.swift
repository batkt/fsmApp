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
