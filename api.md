# Мэдэгдэл (Notification) API Documentation

This document describes the notification system (medegdel) API for the FSM application. Notifications are stored in the FSM database and can be delivered in real-time via Socket.IO.

## 🔐 Authentication

All notification endpoints require Bearer token authentication. The token should be included in the `Authorization` header:

```
Authorization: Bearer <token>
```

The token is validated using the same `APP_SECRET` as `tureesBack` for compatibility.

---

## 📋 REST API Endpoints

### Base URL
```
http://localhost:8000
```

---

### 1. Get Notifications

Get a list of notifications with optional filters.

**Endpoint:** `GET /medegdel`  
**Auth:** Required (Bearer token)

**Query Parameters:**

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `ajiltniiId` | String | Filter by employee ID (auto-filled from token) | No |
| `baiguullagiinId` | String | Filter by organization ID | No |
| `barilgiinId` | String | Filter by construction site ID | No |
| `projectId` | String | Filter by project ID | No |
| `taskId` | String | Filter by task ID | No |
| `turul` | String | Filter by notification type | No |
| `kharsanEsekh` | Boolean | Filter by read status (`true`/`false`) | No |

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "69a52aa0cfb03e9a3d5cff75",
      "ajiltniiId": "695c57521a8a4aebc1d65b05",
      "baiguullagiinId": "695c57511a8a4aebc1d65b02",
      "barilgiinId": "695c57511a8a4aebc1d65b03",
      "projectId": "69a52aa0cfb03e9a3d5cff75",
      "taskId": "69a28bd791593791d03b06df",
      "turul": "taskCreated",
      "title": "Шинэ даалгавар",
      "message": "Даалгавар танд хуваарилагдлаа",
      "kharsanEsekh": false,
      "zurag": "https://example.com/image.jpg",
      "object": {
        "_id": "69a28bd791593791d03b06df",
        "ner": "Даалгавар",
        "taskId": "БАР-0001"
      },
      "tuluv": 0,
      "dakhijKharakhguiAjiltniiIdnuud": [],
      "dakhijKharikhEsekh": false,
      "createdAt": "2026-03-02T06:13:52.934Z",
      "updatedAt": "2026-03-02T06:13:52.934Z"
    }
  ]
}
```

**Example:**
```javascript
// Get all unread notifications for current user
const response = await fetch('http://localhost:8000/medegdel?kharsanEsekh=false', {
  headers: {
    'Authorization': 'Bearer <token>'
  }
});

// Get notifications for a specific project
const response = await fetch('http://localhost:8000/medegdel?projectId=69a52aa0cfb03e9a3d5cff75', {
  headers: {
    'Authorization': 'Bearer <token>'
  }
});
```

---

### 2. Get Unread Count

Get the count of unread notifications for a user.

**Endpoint:** `GET /medegdel/unread-count`  
**Auth:** Required (Bearer token)

**Query Parameters:**

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `ajiltniiId` | String | Employee ID (auto-filled from token) | No |
| `baiguullagiinId` | String | Filter by organization ID | No |

**Response:**
```json
{
  "success": true,
  "count": 5
}
```

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel/unread-count', {
  headers: {
    'Authorization': 'Bearer <token>'
  }
});
const { count } = await response.json();
console.log(`Unread notifications: ${count}`);
```

---

### 3. Get Single Notification

Get a single notification by ID.

**Endpoint:** `GET /medegdel/:id`  
**Auth:** Required (Bearer token)

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "69a52aa0cfb03e9a3d5cff75",
    "ajiltniiId": "695c57521a8a4aebc1d65b05",
    "title": "Шинэ даалгавар",
    "message": "Даалгавар танд хуваарилагдлаа",
    "kharsanEsekh": false,
    // ... other fields
  }
}
```

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel/69a52aa0cfb03e9a3d5cff75', {
  headers: {
    'Authorization': 'Bearer <token>'
  }
});
```

---

### 4. Create Notification

Create a new notification.

**Endpoint:** `POST /medegdel`  
**Auth:** Required (Bearer token)

**Request Body:**
```json
{
  "ajiltniiId": "695c57521a8a4aebc1d65b05",
  "baiguullagiinId": "695c57511a8a4aebc1d65b02",
  "barilgiinId": "695c57511a8a4aebc1d65b03",
  "projectId": "69a52aa0cfb03e9a3d5cff75",
  "taskId": "69a28bd791593791d03b06df",
  "turul": "taskCreated",
  "title": "Шинэ даалгавар",
  "message": "Даалгавар танд хуваарилагдлаа",
  "zurag": "https://example.com/image.jpg",
  "object": {
    "taskId": "БАР-0001",
    "ner": "Даалгавар"
  }
}
```

**Fields:**

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `ajiltniiId` | String | Employee who receives notification | Yes |
| `baiguullagiinId` | String | Organization ID | Yes |
| `barilgiinId` | String | Construction site ID | Yes |
| `projectId` | String | Project ID (FSM) | No |
| `taskId` | String | Task ID (FSM) | No |
| `turul` | String | Notification type (see types below) | No |
| `title` | String | Notification title | Yes |
| `message` | String | Notification message | Yes |
| `zurag` | String | Image URL | No |
| `object` | Object | Related object data | No |

**Notification Types (`turul`):**
- `medegdel` - General notification (default)
- `taskCreated` - Task created
- `taskUpdated` - Task updated
- `taskCompleted` - Task completed
- `projectCreated` - Project created
- `projectUpdated` - Project updated
- `chatMessage` - Chat message notification
- `assignment` - Assignment notification
- `reminder` - Reminder notification

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "69a52aa0cfb03e9a3d5cff75",
    "ajiltniiId": "695c57521a8a4aebc1d65b05",
    "title": "Шинэ даалгавар",
    "message": "Даалгавар танд хуваарилагдлаа",
    "kharsanEsekh": false,
    "tuluv": 0,
    "createdAt": "2026-03-02T06:13:52.934Z",
    // ... other fields
  }
}
```

**Note:** Creating a notification automatically emits a `new_notification` Socket.IO event to:
- `user_{ajiltniiId}` room
- `project_{projectId}` room (if projectId provided)
- `task_{taskId}` room (if taskId provided)

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <token>'
  },
  body: JSON.stringify({
    ajiltniiId: '695c57521a8a4aebc1d65b05',
    baiguullagiinId: '695c57511a8a4aebc1d65b02',
    barilgiinId: '695c57511a8a4aebc1d65b03',
    projectId: '69a52aa0cfb03e9a3d5cff75',
    taskId: '69a28bd791593791d03b06df',
    turul: 'taskCreated',
    title: 'Шинэ даалгавар',
    message: 'Даалгавар танд хуваарилагдлаа'
  })
});
```

---

### 5. Update Notification

Update a notification.

**Endpoint:** `PUT /medegdel/:id`  
**Auth:** Required (Bearer token)

**Request Body:** Any fields to update (same structure as create)

**Response:**
```json
{
  "success": true,
  "data": {
    // Updated notification object
  }
}
```

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel/69a52aa0cfb03e9a3d5cff75', {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <token>'
  },
  body: JSON.stringify({
    title: 'Updated Title',
    message: 'Updated message'
  })
});
```

---

### 6. Mark Notification as Read

Mark a single notification as read.

**Endpoint:** `PUT /medegdel/:id/read`  
**Auth:** Required (Bearer token)

**Request Body (Optional):**
```json
{
  "ajiltniiId": "695c57521a8a4aebc1d65b05"
}
```

**Note:** `ajiltniiId` is auto-filled from token if not provided.

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "69a52aa0cfb03e9a3d5cff75",
    "kharsanEsekh": true,
    "tuluv": 1,
    // ... other fields
  }
}
```

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel/69a52aa0cfb03e9a3d5cff75/read', {
  method: 'PUT',
  headers: {
    'Authorization': 'Bearer <token>'
  }
});
```

---

### 7. Mark All Notifications as Read

Mark all unread notifications as read for a user.

**Endpoint:** `PUT /medegdel/read-all`  
**Auth:** Required (Bearer token)

**Query Parameters:**

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `ajiltniiId` | String | Employee ID (auto-filled from token) | No |
| `baiguullagiinId` | String | Filter by organization ID | No |

**Request Body (Optional):**
```json
{
  "ajiltniiId": "695c57521a8a4aebc1d65b05"
}
```

**Response:**
```json
{
  "success": true,
  "message": "5 мэдэгдэл уншсан болголоо",
  "count": 5
}
```

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel/read-all', {
  method: 'PUT',
  headers: {
    'Authorization': 'Bearer <token>'
  }
});
const { count } = await response.json();
console.log(`Marked ${count} notifications as read`);
```

---

### 8. Delete Notification

Delete a notification.

**Endpoint:** `DELETE /medegdel/:id`  
**Auth:** Required (Bearer token)

**Response:**
```json
{
  "success": true,
  "message": "Мэдэгдэл устгагдлаа"
}
```

**Example:**
```javascript
const response = await fetch('http://localhost:8000/medegdel/69a52aa0cfb03e9a3d5cff75', {
  method: 'DELETE',
  headers: {
    'Authorization': 'Bearer <token>'
  }
});
```

---

## 🔌 Socket.IO Events

### Receiving Notifications (Real-time)

Notifications are automatically emitted via Socket.IO when created. Listen for the `new_notification` event.

**Event:** `new_notification`  
**Rooms:**
- `user_{ajiltniiId}` - User-specific notifications
- `project_{projectId}` - Project-related notifications
- `task_{taskId}` - Task-related notifications

**Payload:** Same structure as notification object

**Example:**
```javascript
import { io } from "socket.io-client";

const socket = io("http://localhost:8000");

// Join user notification room
socket.emit("join_notifications", {
  userId: "695c57521a8a4aebc1d65b05"
});

// Listen for new notifications
socket.on("new_notification", (notification) => {
  console.log("New notification:", notification);
  
  // Show notification badge
  updateNotificationBadge();
  
  // Display notification toast
  showNotificationToast(notification);
  
  // Add to notification list
  addToNotificationList(notification);
});
```

See [SOCKET_API.md](./SOCKET_API.md) for more Socket.IO details.

---

## 📊 Data Model

### Notification Schema

```typescript
{
  _id: ObjectId,
  ajiltniiId: String,              // Employee who receives notification
  khariltsagchiinId: String,       // Customer ID (if applicable)
  baiguullagiinId: String,         // Organization ID (required)
  barilgiinId: String,              // Construction site ID (required)
  khuleenAvagchiinId: String,       // Recipient ID
  projectId: String,                // FSM: Link to project
  taskId: String,                   // FSM: Link to task
  turul: String,                    // Notification type
  title: String,                    // Notification title (required)
  message: String,                   // Notification message (required)
  kharsanEsekh: Boolean,            // Read status (default: false)
  zurag: String,                    // Image URL
  object: Mixed,                    // Related object data
  adminMedegdelId: String,          // For admin notifications
  tuluv: Number,                    // Status: 0 = unread, 1 = read (default: 0)
  dakhijKharakhguiAjiltniiIdnuud: [String], // Employees who haven't seen
  dakhijKharikhEsekh: Boolean,      // All seen (default: false)
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes

- `{ ajiltniiId: 1, kharsanEsekh: 1, createdAt: -1 }` - Efficient queries for user notifications
- `{ baiguullagiinId: 1, barilgiinId: 1 }` - Organization queries
- `{ projectId: 1, taskId: 1 }` - Project/task queries
- `{ turul: 1, createdAt: -1 }` - Type-based queries

---

## 🔄 Automatic Notifications

The system automatically creates notifications for certain events:

### 1. Task Created
- **Trigger:** When a task is created via `POST /tasks`
- **Recipient:** Assigned user (`hariutsagchId`)
- **Type:** `taskCreated`
- **Title:** "Шинэ даалгавар"
- **Message:** "{task.ner} ({task.taskId}) даалгавар танд хуваарилагдлаа"

### 2. Task Completed
- **Trigger:** When a task is updated with `tuluv: "duussan"`
- **Recipient:** Assigned user (`hariutsagchId`)
- **Type:** `taskCompleted`
- **Title:** "Даалгавар дууссан"
- **Message:** "{task.ner} ({task.taskId}) даалгавар амжилттай дууссан"

### 3. Project Created
- **Trigger:** When a project is created via `POST /projects`
- **Recipients:** Project manager (`udirdagchId`) and all project members (`ajiltnuud`)
- **Type:** `projectCreated`
- **Title:** "Шинэ төсөл"
- **Message:** 
  - For manager: "{project.ner} төсөл үүсгэгдлээ"
  - For members: "{project.ner} төсөлд танд хандалт олгогдлоо"

---

## 💡 Usage Examples

### Complete Notification Flow

```javascript
// 1. Connect to Socket.IO
const socket = io("http://localhost:8000");

// 2. Join notification room
socket.on("connect", () => {
  socket.emit("join_notifications", {
    userId: "695c57521a8a4aebc1d65b05"
  });
});

// 3. Listen for real-time notifications
socket.on("new_notification", (notification) => {
  console.log("New notification:", notification);
  updateUI(notification);
});

// 4. Get unread count on page load
async function loadNotifications() {
  const response = await fetch('http://localhost:8000/medegdel/unread-count', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  const { count } = await response.json();
  updateNotificationBadge(count);
}

// 5. Get notification list
async function getNotifications() {
  const response = await fetch('http://localhost:8000/medegdel?kharsanEsekh=false', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  const { data } = await response.json();
  displayNotifications(data);
}

// 6. Mark notification as read when clicked
async function markAsRead(notificationId) {
  await fetch(`http://localhost:8000/medegdel/${notificationId}/read`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  // Update UI
  updateNotificationStatus(notificationId, true);
}

// 7. Mark all as read
async function markAllAsRead() {
  const response = await fetch('http://localhost:8000/medegdel/read-all', {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  const { count } = await response.json();
  console.log(`Marked ${count} notifications as read`);
}
```

### React Example

```jsx
import { useEffect, useState } from 'react';
import { io } from 'socket.io-client';

function NotificationComponent({ userId, token }) {
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    // Connect to socket
    const socket = io("http://localhost:8000");
    
    // Join notification room
    socket.emit("join_notifications", { userId });
    
    // Listen for new notifications
    socket.on("new_notification", (notification) => {
      setNotifications(prev => [notification, ...prev]);
      setUnreadCount(prev => prev + 1);
    });
    
    // Load initial notifications
    loadNotifications();
    
    return () => {
      socket.disconnect();
    };
  }, [userId]);

  const loadNotifications = async () => {
    // Get unread count
    const countRes = await fetch('http://localhost:8000/medegdel/unread-count', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const { count } = await countRes.json();
    setUnreadCount(count);
    
    // Get notifications
    const notifRes = await fetch('http://localhost:8000/medegdel', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const { data } = await notifRes.json();
    setNotifications(data);
  };

  const markAsRead = async (id) => {
    await fetch(`http://localhost:8000/medegdel/${id}/read`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    setNotifications(prev => 
      prev.map(n => n._id === id ? { ...n, kharsanEsekh: true } : n)
    );
    setUnreadCount(prev => Math.max(0, prev - 1));
  };

  return (
    <div>
      <div>Unread: {unreadCount}</div>
      {notifications.map(notif => (
        <div 
          key={notif._id}
          onClick={() => markAsRead(notif._id)}
          style={{ 
            opacity: notif.kharsanEsekh ? 0.5 : 1 
          }}
        >
          <h3>{notif.title}</h3>
          <p>{notif.message}</p>
        </div>
      ))}
    </div>
  );
}
```

---

## ⚠️ Notes

- Notifications are stored in the FSM database (`fManageFsm`)
- All endpoints require Bearer token authentication
- `ajiltniiId` is automatically extracted from the token if not provided
- `baiguullagiinId` is automatically extracted from the token if not provided
- Notifications are automatically emitted via Socket.IO when created
- Always join the notification room (`join_notifications`) to receive real-time updates
- Use `kharsanEsekh: false` to filter unread notifications
- The `tuluv` field: `0` = unread, `1` = read
- Notifications are sorted by `createdAt` descending (newest first)

---

## 🔗 Related Documentation

- [SOCKET_API.md](./SOCKET_API.md) - Socket.IO events and real-time communication
- [CHAT_WEBSOCKET.md](./CHAT_WEBSOCKET.md) - Chat system documentation
- [MOBILE_API.md](./MOBILE_API.md) - Mobile API documentation
