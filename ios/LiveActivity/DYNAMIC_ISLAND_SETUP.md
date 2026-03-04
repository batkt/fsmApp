# Dynamic Island / Live Activities Setup Guide

## Overview

This guide explains how to set up Dynamic Island (Live Activities) for iOS to show real-time task progress in the Dynamic Island and Lock Screen.

## Requirements

- **iOS 16.1+** (for Live Activities)
- **iPhone 14 Pro or later** (for Dynamic Island hardware)
- **Apple Developer Program** (paid account required)
- **Xcode 14+**

## Step 1: Create Activity Extension Target

1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to **File → New → Target**
3. Select **"Widget Extension"**
4. Configure:
   - **Product Name**: `LiveActivity` (or `TaskLiveActivity`)
   - **Organization Identifier**: `com.example` (match your app)
   - **Language**: Swift
   - **Include Configuration Intent**: ❌ No
5. Click **Finish**
6. When prompted "Activate LiveActivity scheme?", click **Cancel**

## Step 2: Replace Generated Files

1. Delete auto-generated files in the `LiveActivity` folder:
   - `LiveActivity/LiveActivity.swift` (or similar)
   - `LiveActivity/LiveActivityBundle.swift` (or similar)

2. Copy our files:
   - Copy `ios/LiveActivity/TaskLiveActivity.swift` → `LiveActivity/TaskLiveActivity.swift`
   - Copy `ios/LiveActivity/LiveActivityManager.swift` → `LiveActivity/LiveActivityManager.swift`

## Step 3: Configure App Groups

**For Runner Target:**
1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Add **"App Groups"** capability (if not already added)
4. Ensure `group.com.example.fsmapp` is checked

**For LiveActivity Target:**
1. Select **LiveActivity** target
2. Go to **Signing & Capabilities**
3. Add **"App Groups"** capability
4. Check `group.com.example.fsmapp`

## Step 4: Enable Live Activities Entitlement

**For Runner Target:**
1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Click **"+ Capability"**
4. Add **"Live Activities"**
5. Enable **"Live Activities"** toggle

**For LiveActivity Target:**
1. Select **LiveActivity** target
2. Go to **Signing & Capabilities**
3. Add **"Live Activities"** capability
4. Enable **"Live Activities"** toggle

## Step 5: Update Info.plist

**For LiveActivity Target:**
1. Select **LiveActivity** target
2. Go to **Info** tab
3. Add to `Info.plist`:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

## Step 6: Update AppDelegate

The `AppDelegate.swift` already has the MethodChannel handler. You need to:

1. Import `LiveActivityManager` in `AppDelegate.swift`:
   ```swift
   import LiveActivityManager // If in separate module
   // OR copy LiveActivityManager code directly into AppDelegate
   ```

2. Update the `liveActivityChannel` handler to use `LiveActivityManager`:
   ```swift
   case "startTaskActivity":
     if let args = call.arguments as? [String: Any],
        let taskId = args["taskId"] as? String,
        let taskCode = args["taskCode"] as? String,
        let taskTitle = args["taskTitle"] as? String {
       let elapsedTime = args["elapsedTime"] as? String ?? "00:00:00"
       let progress = args["progress"] as? Int ?? 0
       let status = args["status"] as? String ?? "Явагдаж буй"
       LiveActivityManager.shared.startTaskActivity(
         taskId: taskId,
         taskCode: taskCode,
         taskTitle: taskTitle,
         elapsedTime: elapsedTime,
         progress: progress,
         status: status
       )
       result(true)
     } else {
       result(false)
     }
   ```

## Step 7: Update Bundle Identifier

**LiveActivity Target:**
1. Select **LiveActivity** target
2. Go to **General** tab
3. Set **Bundle Identifier** to: `com.example.fsmapp.LiveActivity`

## Step 8: Update Deployment Target

**LiveActivity Target:**
1. Select **LiveActivity** target
2. Go to **General** tab
3. Set **iOS Deployment Target** to **16.1** or higher

## Step 9: Build and Test

1. Select **LiveActivity** scheme
2. Build (⌘+B) to check for errors
3. Switch back to **Runner** scheme
4. Run on a **real device** (iPhone 14 Pro or later for Dynamic Island)
   - Simulator supports Live Activities on iOS 18+
   - Dynamic Island requires physical hardware

## Step 10: Test Live Activity

1. Start a task in the app
2. The Live Activity should appear:
   - **Lock Screen**: Full Live Activity view
   - **Dynamic Island** (iPhone 14 Pro+): Compact pill view
   - **Tap Dynamic Island**: Expands to show full details

## How It Works

### Data Flow

1. **Flutter App** → `TaskTrackerService.startTask()` called
2. **Flutter** → MethodChannel `com.example.fsmapp/live_activity`
3. **iOS AppDelegate** → Calls `LiveActivityManager.startTaskActivity()`
4. **ActivityKit** → Creates Live Activity with `TaskLiveActivityAttributes`
5. **Dynamic Island** → Displays compact/minimal/expanded views
6. **Lock Screen** → Shows full Live Activity view

### Update Flow

1. **Flutter App** → `TaskTrackerService.updateLiveProgress()` called every second
2. **Flutter** → MethodChannel with elapsed time and progress
3. **iOS AppDelegate** → Calls `LiveActivityManager.updateTaskActivity()`
4. **ActivityKit** → Updates Live Activity state
5. **Dynamic Island** → Updates in real-time

### End Flow

1. **Flutter App** → `TaskTrackerService.stopTask()` called
2. **iOS AppDelegate** → Calls `LiveActivityManager.endTaskActivity()`
3. **ActivityKit** → Ends Live Activity with final state
4. **Dynamic Island** → Dismisses

## Troubleshooting

### Live Activity Not Appearing

- ✅ Check Live Activities are enabled in Settings → Face ID & Passcode → Live Activities
- ✅ Verify App Groups are configured for both targets
- ✅ Ensure Live Activities entitlement is enabled
- ✅ Check iOS version is 16.1+
- ✅ Test on real device (iPhone 14 Pro+ for Dynamic Island)

### Build Errors

- ✅ Ensure `ActivityKit` framework is imported
- ✅ Check deployment target is 16.1+
- ✅ Verify bundle identifiers match
- ✅ Check Info.plist has `NSSupportsLiveActivities`

### Dynamic Island Not Showing

- ✅ Requires iPhone 14 Pro or later (hardware requirement)
- ✅ Check Live Activities are enabled in system settings
- ✅ Verify the activity is actually started (check logs)
- ✅ Test on physical device, not simulator (unless iOS 18+)

## Notes

- **Dynamic Island** is hardware-specific (iPhone 14 Pro+)
- **Live Activities** work on all iOS 16.1+ devices (shows on Lock Screen)
- **Simulator** supports Live Activities on iOS 18+
- **Push Notifications** can update Live Activities remotely (requires server setup)
- **Privacy**: Ensure user data displayed in Dynamic Island is appropriate

## Next Steps

1. Test on real device
2. Monitor battery usage (Live Activities are efficient)
3. Consider server-driven updates for long-running tasks
4. Add interactive buttons (iOS 17+) if needed
