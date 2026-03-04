# Samsung Now Bar / Live Notifications Setup Guide

## Overview

This guide explains how to enable Samsung One UI 7+ Live Notifications and Now Bar support for the task tracker notification.

## Requirements

- **Samsung One UI 7+** (Android 14+)
- **Samsung device** (Galaxy S series, Note series, etc.)
- **Whitelisting** (required for Now Bar - see below)

## Current Implementation

The app already includes:

1. ✅ **Samsung metadata** in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.samsung.android.support.ongoing_activity"
       android:value="true" />
   ```

2. ✅ **Notification extras** in `TaskTrackerService.kt`:
   - `android.ongoingActivityNoti.style`
   - `android.ongoingActivityNoti.primaryInfo`
   - `android.ongoingActivityNoti.secondaryInfo`
   - `android.ongoingActivityNoti.nowbarPrimaryInfo`
   - `android.ongoingActivityNoti.nowbarSecondaryInfo`
   - And more...

3. ✅ **Android 14+ Live Updates**:
   - `POST_PROMOTED_NOTIFICATIONS` permission
   - `setRequestPromotedOngoing(true)` for status bar chip

## How It Works

### Notification Flow

1. **Flutter App** → `TaskTrackerService.startTask()` called
2. **Android** → `TaskTrackerService` creates foreground notification
3. **Samsung One UI** → Reads notification extras
4. **Now Bar** → Displays chip in top-left corner (if whitelisted)

### Update Flow

1. **Flutter App** → `TaskTrackerService.updateLiveProgress()` called every second
2. **Android** → Updates notification with new progress/time
3. **Samsung One UI** → Updates Now Bar chip in real-time

## Samsung Whitelisting (Required)

**Important**: Samsung One UI only honors Now Bar extras for whitelisted apps. You must request whitelisting from Samsung.

### Step 1: Prepare Demo Materials

1. **Signed APK** with current implementation
2. **Demo Video/GIF** showing:
   - Task starting
   - Now Bar chip appearing
   - Real-time updates
   - Task completion
3. **Notification Extras Payload** (document the extras being used)
4. **Privacy Policy** (if user data is displayed)

### Step 2: Contact Samsung Developer Support

**Website**: https://developer.samsung.com

**Email Template**:

```
Subject: Request: Whitelist com.example.fsmapp for One UI Live Notifications / Now Bar

Hello Samsung Developer Support,

We request whitelisting for package com.example.fsmapp so that One UI honors Live Notification / Now Bar extras.

Package Name: com.example.fsmapp
App Name: FSM App
Use Case: Task tracking with real-time progress updates requiring lock-screen quick controls and Now Bar metadata.

Attachments:
- Signed APK
- Demo video/GIF
- Notification extras payload
- Privacy policy

Notification Extras Being Used:
- android.ongoingActivityNoti.style: 1 (progress/timer)
- android.ongoingActivityNoti.primaryInfo: Task code
- android.ongoingActivityNoti.secondaryInfo: Elapsed time
- android.ongoingActivityNoti.nowbarPrimaryInfo: Task code
- android.ongoingActivityNoti.nowbarSecondaryInfo: Time and progress

Please advise next steps or documentation for whitelisting.

Thanks,
[Your Name / Company]
```

### Step 3: Wait for Approval

- Samsung will review your request
- Approval typically takes 1-2 weeks
- You'll receive confirmation email

### Step 4: Test on Device

Once whitelisted:
1. Install app on Samsung device
2. Start a task
3. Check top-left corner for Now Bar chip
4. Verify real-time updates work

## Testing Without Whitelisting

Even without whitelisting, you can test:

1. **Notification appears** in notification shade
2. **Foreground service** runs correctly
3. **Updates work** in notification
4. **Now Bar chip** won't appear until whitelisted

## Current Notification Extras

The app sets these Samsung-specific extras:

```kotlin
val extras = bundleOf(
    "android.ongoingActivityNoti.style" to 1, // Progress/timer style
    "android.ongoingActivityNoti.primaryInfo" to taskCode,
    "android.ongoingActivityNoti.secondaryInfo" to elapsedTime,
    "android.ongoingActivityNoti.chipBgColor" to green color,
    "android.ongoingActivityNoti.chipIcon" to notification icon,
    "android.ongoingActivityNoti.chipExpandedText" to "Явц: $taskCode",
    "android.ongoingActivityNoti.actionType" to 1, // Progress action
    "android.ongoingActivityNoti.nowbarPrimaryInfo" to taskCode,
    "android.ongoingActivityNoti.nowbarSecondaryInfo" to "$elapsedTime | $progress%"
)
```

## Troubleshooting

### Now Bar Chip Not Appearing

- ✅ Check device is Samsung with One UI 7+
- ✅ Verify app is whitelisted (contact Samsung)
- ✅ Check notification extras are set correctly
- ✅ Ensure notification is ongoing (`setOngoing(true)`)
- ✅ Verify notification channel importance is `IMPORTANCE_DEFAULT` or higher

### Notification Not Updating

- ✅ Check `updateLiveProgress()` is being called
- ✅ Verify `startForeground()` is used for updates
- ✅ Check notification ID matches
- ✅ Ensure notification channel allows updates

### Build Errors

- ✅ Check `bundleOf` import: `androidx.core.os.bundleOf`
- ✅ Verify `Icon.createWithResource()` is available (API 23+)
- ✅ Check all imports are correct

## Notes

- **Whitelisting is required** for Now Bar to appear
- **Android 14+ Live Updates** work without whitelisting (status bar chip)
- **Samsung-specific** extras are ignored on non-Samsung devices
- **Testing** can be done on any Android device, but Now Bar requires Samsung

## Next Steps

1. Prepare whitelisting request materials
2. Contact Samsung Developer Support
3. Test on Samsung device once whitelisted
4. Monitor user feedback for Now Bar visibility
