# iOS Widget Setup Guide

## Overview

iOS widgets have been implemented to match the Android widget functionality. The code is ready, but you need to complete the Xcode configuration.

## Files Created

1. **`ios/Widgets/TaskWidget.swift`** - Task widget implementation
2. **`ios/Widgets/NotificationWidget.swift`** - Notification widget implementation  
3. **`ios/Widgets/Info.plist`** - Widget extension Info.plist
4. **`ios/Runner/AppDelegate.swift`** - Updated with widget MethodChannel handler

## Required Xcode Setup Steps

### Step 1: Create Widget Extension Target

1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to **File → New → Target**
3. Select **"Widget Extension"**
4. Configure:
   - **Product Name**: `Widgets`
   - **Organization Identifier**: `com.example` (or match your app's)
   - **Language**: Swift
   - **Include Configuration Intent**: ❌ No
5. Click **Finish**
6. When prompted "Activate Widget Extension scheme?", click **Cancel** (we'll activate it later)

### Step 2: Replace Generated Files

1. Delete the auto-generated widget files in the `Widgets` folder:
   - `Widgets/Widgets.swift` (or similar)
   - `Widgets/WidgetsBundle.swift` (or similar)

2. Copy our widget files:
   - Copy `ios/Widgets/TaskWidget.swift` → `Widgets/TaskWidget.swift`
   - Copy `ios/Widgets/NotificationWidget.swift` → `Widgets/NotificationWidget.swift`
   - Copy `ios/Widgets/Info.plist` → `Widgets/Info.plist` (replace existing)

### Step 3: Configure App Groups

**For Runner Target:**
1. Select **Runner** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **"+ Capability"**
4. Add **"App Groups"**
5. Click **"+**" to add a new group
6. Enter: `group.com.example.fsmapp`
7. ✅ Check the box next to it

**For Widgets Target:**
1. Select **Widgets** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **"+ Capability"**
4. Add **"App Groups"**
5. ✅ Check the box next to `group.com.example.fsmapp` (should appear automatically)

### Step 4: Update Bundle Identifiers

**Widgets Target:**
1. Select **Widgets** target
2. Go to **General** tab
3. Ensure **Bundle Identifier** is: `com.example.fsmapp.Widgets` (or match your app's bundle ID + `.Widgets`)

### Step 5: Update Deployment Target

**Widgets Target:**
1. Select **Widgets** target
2. Go to **General** tab
3. Set **iOS Deployment Target** to **iOS 14.0** or higher (WidgetKit requires iOS 14+)

### Step 6: Build and Test

1. Select **Widgets** scheme from the scheme dropdown
2. Build (⌘+B) to ensure there are no compilation errors
3. Switch back to **Runner** scheme
4. Run the app (⌘+R)

### Step 7: Add Widget to Home Screen

1. Long press on home screen
2. Tap **"+"** in top-left
3. Search for your app name
4. Select **"Даалгаврууд"** (Task Widget) or **"Мэдэгдэл"** (Notification Widget)
5. Choose size (Medium or Large)
6. Tap **"Add Widget"**

## How It Works

### Data Flow

1. **Flutter App** → `WidgetService.updateWidget()` writes data to `SharedPreferences`
2. **Flutter App** → Calls `writeToAppGroup()` via MethodChannel
3. **iOS AppDelegate** → Writes data to App Group `UserDefaults` (`group.com.example.fsmapp`)
4. **Widget Extension** → Reads data from App Group `UserDefaults`
5. **Widget Extension** → Displays data in SwiftUI views
6. **WidgetKit** → Refreshes widget timeline every 15 minutes

### Widget Features

**Task Widget:**
- Shows today's date
- Displays progress (completed/total tasks)
- Lists tasks with status indicators
- Medium: Shows 3 tasks
- Large: Shows up to 8 tasks

**Notification Widget:**
- Shows unread notification count
- Lists notifications with icons and timestamps
- Medium: Shows 3 notifications
- Large: Shows up to 8 notifications

## Troubleshooting

### Widget Not Appearing
- Ensure App Groups are configured for both Runner and Widgets targets
- Check that bundle identifiers match
- Verify iOS Deployment Target is 14.0+

### Widget Not Updating
- Check that `WidgetService.updateWidget()` is being called
- Verify App Group identifier matches: `group.com.example.fsmapp`
- Check Xcode console for errors

### Build Errors
- Ensure WidgetKit framework is imported
- Check that all Swift files are added to the Widgets target
- Verify Info.plist is correctly configured

## Notes

- Widgets automatically refresh every 15 minutes
- Widgets can be manually refreshed by pulling down on the home screen
- Widget data is shared via App Groups, not standard SharedPreferences
- The Flutter `WidgetService` handles both Android and iOS automatically
