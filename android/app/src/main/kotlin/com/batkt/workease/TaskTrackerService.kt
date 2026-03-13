package com.batkt.workease

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.content.pm.ServiceInfo
import androidx.core.app.NotificationCompat

class TaskTrackerService : Service() {
    companion object {
        private const val CHANNEL_ID = "task_tracker_channel"
        private const val CHANNEL_NAME = "Task Tracker"
        private const val NOTIFICATION_ID = 2001

        fun start(context: Context, taskId: String, code: String, title: String) {
            val intent = Intent(context, TaskTrackerService::class.java).apply {
                putExtra("taskId", taskId)
                putExtra("code", code)
                putExtra("title", title)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, TaskTrackerService::class.java)
            context.stopService(intent)
        }

        fun updateProgress(context: Context, progress: Int, elapsedSeconds: Int) {
            val intent = Intent(context, TaskTrackerService::class.java).apply {
                action = ACTION_UPDATE_PROGRESS
                putExtra("progress", progress)
                putExtra("elapsedSeconds", elapsedSeconds)
            }
            context.startService(intent)
        }

        private const val ACTION_UPDATE_PROGRESS = "com.batkt.workease.UPDATE_PROGRESS"
    }

    private var currentCode: String = ""
    private var currentTitle: String = ""
    private var currentProgress: Int = 0
    private var currentElapsedSeconds: Int = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_UPDATE_PROGRESS -> {
                currentProgress = intent.getIntExtra("progress", 0)
                currentElapsedSeconds = intent.getIntExtra("elapsedSeconds", 0)
                updateNotification()
            }
            else -> {
                // Initial start
                currentCode = intent?.getStringExtra("code") ?: ""
                currentTitle = intent?.getStringExtra("title") ?: ""
                currentProgress = 0
                currentElapsedSeconds = 0
                val notification = buildNotification()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            }
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                // Use IMPORTANCE_DEFAULT for Now Bar compatibility
                // IMPORTANCE_LOW may prevent promotion to Now Bar
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Одоогийн эхэлсэн даалгаврын мэдээлэл"
                    setShowBadge(false)
                    enableVibration(false) // No vibration for live updates
                    enableLights(false) // No LED for live updates
                    setSound(null, null) // No sound for live updates
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    private fun updateNotification() {
        val notification = buildNotification()
        // Use startForeground for foreground service updates to ensure it stays in foreground
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val contentTitle = if (currentCode.isNotEmpty()) {
            "Явц: $currentCode"
        } else {
            "Явц: Даалгавар"
        }

        // Format elapsed time as HH:MM:SS
        val hours = currentElapsedSeconds / 3600
        val minutes = (currentElapsedSeconds % 3600) / 60
        val seconds = currentElapsedSeconds % 60
        val elapsedTime = String.format("%02d:%02d:%02d", hours, minutes, seconds)

        // Content text: "00:15:23 | 45%"
        val contentText = "$elapsedTime | $currentProgress%"

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .setSmallIcon(R.drawable.ic_notification)
            .setProgress(100, currentProgress, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(pendingIntent)
            .setShowWhen(false) // Hide timestamp for cleaner Now Bar display
            .setSilent(true) // Don't make sound on updates
            .setAutoCancel(false) // Keep it persistent
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // Show on lock screen

        // Request promotion to Now Bar / status bar chip (Android 14+)
        // This makes the notification appear as a chip in Samsung's Now Bar
        if (Build.VERSION.SDK_INT >= 34) { // Android 14 (UPSIDE_DOWN_CAKE)
            try {
                builder.setRequestPromotedOngoing(true)
            } catch (e: Exception) {
                // Fallback if method not available
            }
        }

        // Samsung One UI 7+ Now Bar / Live Notification extras
        // These extras enable the notification to appear in Samsung's Now Bar
        // Note: Requires Samsung whitelisting - see SAMSUNG_NOW_BAR_SETUP.md
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val extras = Bundle().apply {
                    putInt("android.ongoingActivityNoti.style", 1) // Style: progress/timer
                    putString("android.ongoingActivityNoti.primaryInfo", currentCode.ifEmpty { "Даалгавар" })
                    putString("android.ongoingActivityNoti.secondaryInfo", elapsedTime)
                    putInt("android.ongoingActivityNoti.chipBgColor", getColor(android.R.color.holo_green_light))
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        putParcelable("android.ongoingActivityNoti.chipIcon", 
                            Icon.createWithResource(this@TaskTrackerService, R.drawable.ic_notification))
                    }
                    putString("android.ongoingActivityNoti.chipExpandedText", "Явц: $currentCode")
                    putInt("android.ongoingActivityNoti.actionType", 1) // Action type: progress
                    putInt("android.ongoingActivityNoti.actionPrimarySet", 0)
                    putString("android.ongoingActivityNoti.nowbarPrimaryInfo", currentCode.ifEmpty { "Даалгавар" })
                    putString("android.ongoingActivityNoti.nowbarSecondaryInfo", "$elapsedTime | $currentProgress%")
                }
                builder.setExtras(extras)
            } catch (e: Exception) {
                // Fallback if extras not supported
                android.util.Log.e("TaskTrackerService", "Failed to set Samsung extras", e)
            }
        }

        return builder.build()
    }
}

