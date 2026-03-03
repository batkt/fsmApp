# Chat Notifications

This document describes how notifications (medegdel) are automatically created when chat messages are sent.

## 🔔 Automatic Notifications

When a chat message is created (text, image, or file), the system automatically creates notifications for all relevant project/task members **except the sender**.

## 📋 Who Gets Notified

### Project Chat Messages
- ✅ Project manager (`udirdagchId`)
- ✅ All project members (`ajiltnuud`)
- ❌ Message sender (excluded)

### Task Chat Messages
- ✅ Project manager (`udirdagchId`)
- ✅ All project members (`ajiltnuud`)
- ✅ Task assigned user (`hariutsagchId`)
- ❌ Message sender (excluded)

## 📨 Notification Details

### Notification Type
- `turul`: `"chatMessage"`

### Title
- Project chat: `"Төслийн мессеж"`
- Task chat: `"Даалгаврын мессеж"`

### Message Format
```
{senderName}: {messagePreview}
```

**Message Preview:**
- Text messages: First 50 characters (truncated with "...")
- Images: `"Зураг илгээлээ"`
- Files: `"Файл илгээлээ"`
- Empty: `"Шинэ мессеж"`

### Additional Fields
- `projectId`: Project ID
- `taskId`: Task ID (if task chat)
- `zurag`: Image URL (if image message)
- `object`: Full chat object for reference

## 🔌 Real-time Delivery

Notifications are automatically emitted via Socket.IO to:
- `user_{userId}` room for each recipient

**Event:** `new_notification`

## 📝 Example

### Chat Message Sent
```json
POST /chats
{
  "projectId": "69a52aa0cfb03e9a3d5cff75",
  "taskId": "69a28bd791593791d03b06df",
  "medeelel": "Ажил эхэллээ, бүх зүйл сайн байна",
  "ajiltniiId": "695c57521a8a4aebc1d65b05",
  "ajiltniiNer": "В. Энх-Амар"
}
```

### Notification Created
```json
{
  "turul": "chatMessage",
  "title": "Даалгаврын мессеж",
  "message": "В. Энх-Амар: Ажил эхэллээ, бүх зүйл сайн байна",
  "projectId": "69a52aa0cfb03e9a3d5cff75",
  "taskId": "69a28bd791593791d03b06df",
  "ajiltniiId": "695c57521a8a4aebc1d65b06", // Recipient
  "kharsanEsekh": false
}
```

## ⚠️ Notes

- Notifications are created **asynchronously** - chat message creation succeeds even if notification creation fails
- Errors in notification creation are logged but don't affect chat functionality
- Sender is **never** notified of their own messages
- Works for both text messages and file/image uploads

## 🔗 Related Documentation

- [MEDEGDEL_API.md](./MEDEGDEL_API.md) - Full notification API
- [SOCKET_API.md](./SOCKET_API.md) - Socket.IO events
- [CHAT_WEBSOCKET.md](./CHAT_WEBSOCKET.md) - Chat system
