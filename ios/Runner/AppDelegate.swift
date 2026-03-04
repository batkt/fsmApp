import Flutter
import UIKit
import WidgetKit

@available(iOS 16.1, *)
import ActivityKit

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
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "NotificationWidget")
        result(true)
      case "updateNotificationWidget":
        // Reload widget timelines (data already written to App Group via writeToAppGroup)
        WidgetCenter.shared.reloadTimelines(ofKind: "NotificationWidget")
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
          // Implementation requires Activity Extension with TaskLiveActivityAttributes
          // See DYNAMIC_ISLAND_SETUP.md for complete setup
          print("[LiveActivity] startTaskActivity called - requires Activity Extension")
          result(false)
        case "updateTaskActivity":
          // Implementation requires Activity Extension
          print("[LiveActivity] updateTaskActivity called - requires Activity Extension")
          result(false)
        case "endTaskActivity":
          // Implementation requires Activity Extension
          print("[LiveActivity] endTaskActivity called - requires Activity Extension")
          result(false)
        case "isAvailable":
          // Check if Live Activities are available
          result(ActivityAuthorizationInfo().areActivitiesEnabled)
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
