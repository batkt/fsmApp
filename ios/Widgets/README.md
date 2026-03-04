# iOS Widget Extension Setup Instructions

This directory contains the iOS WidgetKit extension files. To complete the setup:

## 1. Add Widget Extension Target in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. File → New → Target
3. Select "Widget Extension"
4. Product Name: `Widgets`
5. Organization Identifier: `com.example` (or your identifier)
6. Language: Swift
7. Include Configuration Intent: No
8. Click Finish

## 2. Configure App Groups

1. Select the **Runner** target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "App Groups"
5. Create/select group: `group.com.example.fsmapp`
6. Repeat for the **Widgets** target

## 3. Replace Generated Files

Replace the auto-generated widget files with the files in this directory:
- Replace `Widgets/TaskWidget.swift` with `ios/Widgets/TaskWidget.swift`
- Replace `Widgets/NotificationWidget.swift` with `ios/Widgets/NotificationWidget.swift`
- Replace `Widgets/Info.plist` with `ios/Widgets/Info.plist`

## 4. Update Bundle Identifier

Ensure the Widget extension bundle identifier is:
- `com.example.fsmapp.Widgets` (or match your app's bundle ID + `.Widgets`)

## 5. Build and Run

1. Select the Widgets scheme
2. Build (Cmd+B)
3. Switch back to Runner scheme
4. Run the app

## Notes

- Widgets use App Groups (`group.com.example.fsmapp`) to share data with the main app
- Widgets refresh every 15 minutes automatically
- Widgets can be manually refreshed by calling `WidgetCenter.shared.reloadTimelines()`
- The Flutter `WidgetService` will trigger widget updates on iOS
