# Task Status Notifications System

This document explains how task status (`tuluv`) changes trigger notifications and Socket.IO events, both for manual and automatic updates.

## 📋 Overview

**Every task status change** (manual or automatic) now sends:
- ✅ **Socket.IO events** to project and task rooms
- ✅ **Notifications (medegdel)** to all task members
- ✅ **Push notifications (FCM)** to registered devices

---

## 🔄 Status Transitions

### Task Status Values (`tuluv`)

- `shine` - New/Initial
- `khiigdej bui` - Active/In Progress
- `duussan` - Completed
- `khugatsaa khetersen` - Expired (deadline passed)

### Automatic Status Changes

**1. `shine` → `khiigdej bui` (Auto-activated)**
- **Trigger:** When `ekhlekhTsag` (start time) arrives
- **Notification Type:** `taskStarted`
- **Message:** "Даалгавар эхэлсэн цаг ирлээ"

**2. Any → `khugatsaa khetersen` (Auto-expired)**
- **Trigger:** When `khugatsaaDuusakhOgnoo` (deadline) passes
- **Notification Type:** `taskExpired`
- **Message:** "Даалгаврын хугацаа хэтэрлээ"

### Manual Status Changes

**1. Any → `duussan` (Completed)**
- **Trigger:** User manually marks task as completed
- **Notification Type:** `taskCompleted`
- **Message:** "Даалгавар амжилттай дууссан"

**2. Any → `shine` (Reset)**
- **Trigger:** User resets task to new status
- **Notification Type:** `taskReset`
- **Message:** "Даалгавар дахин шинэ төлөвт шилжлээ"

**3. Any → `khiigdej bui` (Manually started)**
- **Trigger:** User manually starts task
- **Notification Type:** `taskStarted`
- **Message:** "Даалгавар эхэлсэн"

**4. Any → `khugatsaa khetersen` (Manually expired)**
- **Trigger:** User manually marks as expired
- **Notification Type:** `taskExpired`
- **Message:** "Даалгаврын хугацаа хэтэрлээ"

**5. General Update (no status change)**
- **Trigger:** Any other field update
- **Notification Type:** `taskUpdated`
- **Message:** "Даалгавар шинэчлэгдлээ"

---

## 🔔 Notification Recipients

Notifications are sent to **all task members**:
- ✅ Assigned user (`hariutsagchId`)
- ✅ All task members (`ajiltnuud` array)
- ❌ **Excludes:** User who made the update (for manual updates)

For automatic updates, **all members** receive notifications (no one is excluded).

---

## 📡 Socket.IO Events

### Events Emitted

**1. `task_updated`**
- **Rooms:** `project_{projectId}`, `task_{taskId}`
- **Payload:** Complete task object
- **When:** Every status change (manual or automatic)

**2. `new_notification`**
- **Rooms:** `user_{userId}` (individual user rooms)
- **Payload:** Notification object
- **When:** Notification is created

### How to Listen

```javascript
// Join project room
socket.emit("join_room", { projectId: "..." });

// Join task room
socket.emit("join_room", { projectId: "...", taskId: "..." });

// Join notification room
socket.emit("join_notifications", { userId: "..." });

// Listen for task updates
socket.on("task_updated", (task) => {
  console.log("Task updated:", task);
  // Update UI
});

// Listen for notifications
socket.on("new_notification", (notification) => {
  console.log("New notification:", notification);
  // Show notification badge
});
```

---

## 🔄 Automatic Scheduler

The system automatically checks and updates task statuses every **5 minutes** (configurable).

### Configuration

Add to `.env`:
```env
TASK_STATUS_CHECK_INTERVAL=5  # Check every 5 minutes
```

### What It Does

1. **Checks all tasks** for time-based status changes
2. **Updates status** automatically
3. **Sends Socket.IO events** to project/task rooms
4. **Creates notifications** for all task members
5. **Sends push notifications** via FCM

### Logs

You'll see:
```
[Task Status] ✅ Task AFS-0001 (Task Name) activated - start time reached
[Task Status] ⏰ Task AFS-0002 (Task Name) expired - deadline passed
[Task Status] 📊 Updated 2 task(s) based on time
[Task Status] ✅ Notification sent to USER_ID for task AFS-0001 status change: shine → khiigdej bui
```

---

## 📝 Notification Types

All notification types are stored in the `medegdel` collection:

| Type | Description | When |
|------|-------------|------|
| `taskCreated` | Task created | On task creation |
| `taskUpdated` | General update | Any field update (no status change) |
| `taskStarted` | Task started | Status → `khiigdej bui` |
| `taskCompleted` | Task completed | Status → `duussan` |
| `taskExpired` | Task expired | Status → `khugatsaa khetersen` |
| `taskReset` | Task reset | Status → `shine` |
| `taskAssigned` | Task assigned | `hariutsagchId` changed |

---

## 🔌 API Endpoints

### Manual Status Update

```
PUT /tasks/:id
Authorization: Bearer TOKEN
Content-Type: application/json

{
  "tuluv": "duussan"  // or "khiigdej bui", "khugatsaa khetersen", "shine"
}
```

**Response:**
- ✅ Task updated
- ✅ Socket.IO events emitted
- ✅ Notifications created for all members
- ✅ Push notifications sent

### Trigger Status Update for All Tasks

```
POST /task-status/update-all
Authorization: Bearer TOKEN
```

**Response:**
```json
{
  "success": true,
  "message": "Updated 2 task(s)",
  "details": [
    {
      "taskId": "...",
      "action": "activated",
      "oldStatus": "shine",
      "newStatus": "khiigdej bui"
    }
  ]
}
```

### Update Single Task Status

```
POST /task-status/update/:taskId
Authorization: Bearer TOKEN
```

### Calculate Status (Without Updating)

```
GET /task-status/calculate/:taskId
Authorization: Bearer TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "currentStatus": "shine",
    "calculatedStatus": "khiigdej bui",
    "shouldUpdate": true,
    "task": { ... }
  }
}
```

---

## 📊 Complete Flow Example

### Scenario: Task Auto-Activates

1. **Task created** with `ekhlekhTsag: "2026-03-03T10:00:00Z"` and `tuluv: "shine"`

2. **At 10:00 AM** (scheduler runs):
   - ✅ Status updated: `shine` → `khiigdej bui`
   - ✅ Socket.IO: `task_updated` emitted to `project_{id}` and `task_{id}`
   - ✅ Notifications created for all members
   - ✅ Push notifications sent via FCM

3. **Users receive:**
   - Real-time update via Socket.IO (if connected)
   - Notification in database
   - Push notification on device (if registered)

### Scenario: Task Expires

1. **Task** has `khugatsaaDuusakhOgnoo: "2026-03-03T15:00:00Z"` and `tuluv: "khiigdej bui"`

2. **After 3:00 PM** (scheduler runs):
   - ✅ Status updated: `khiigdej bui` → `khugatsaa khetersen`
   - ✅ Socket.IO: `task_updated` emitted
   - ✅ Notifications created: "Даалгаврын хугацаа хэтэрлээ"
   - ✅ Push notifications sent

---

## ✅ Summary

**Every task status change** (manual or automatic) now:
1. ✅ Updates database
2. ✅ Emits Socket.IO events (`task_updated`)
3. ✅ Creates notifications (`medegdel`) for all members
4. ✅ Sends push notifications (FCM) to registered devices
5. ✅ Logs all actions for debugging

**Users are always informed** about task status changes, whether they:
- Made the change manually
- The change happened automatically
- Are online or offline (via push notifications)

---

## 🔍 Debugging

### Check Scheduler Status

```
GET /task-status/scheduler
Authorization: Bearer TOKEN
```

### Check Logs

Look for:
- `[Task Status]` - Automatic status updates
- `[Task Update]` - Manual updates
- `[FCM]` - Push notification sending
- `[Socket.IO]` - Real-time events

### Test Manual Update

```bash
PUT /tasks/TASK_ID
{
  "tuluv": "duussan"
}
```

Expected:
- ✅ Status updated
- ✅ Socket.IO events emitted
- ✅ Notifications created
- ✅ Push notifications sent

---

## 🎯 Key Points

1. **All status changes** trigger notifications (manual + automatic)
2. **All task members** receive notifications (except updater for manual)
3. **Socket.IO + Notifications + Push** all work together
4. **Automatic scheduler** runs every 5 minutes
5. **Status-specific messages** for better UX
