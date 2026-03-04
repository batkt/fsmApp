package com.batkt.workease

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val WIDGET_CHANNEL = "com.batkt.workease/widget"
    private val TASK_TRACKER_CHANNEL = "com.batkt.workease/task_tracker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing widget update channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        updateTaskWidget()
                        result.success(true)
                    }
                    "updateNotificationWidget" -> {
                        updateNotifWidget()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // New task tracker channel for foreground service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASK_TRACKER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val args = call.arguments as? Map<*, *>
                        val taskId = args?.get("taskId") as? String ?: ""
                        val code = args?.get("code") as? String ?: ""
                        val title = args?.get("title") as? String ?: ""
                        TaskTrackerService.start(this, taskId, code, title)
                        result.success(true)
                    }
                    "updateLiveProgress" -> {
                        val args = call.arguments as? Map<*, *>
                        val progress = (args?.get("progress") as? Number)?.toInt() ?: 0
                        val elapsedSeconds = (args?.get("elapsedSeconds") as? Number)?.toInt() ?: 0
                        TaskTrackerService.updateProgress(this, progress, elapsedSeconds)
                        result.success(true)
                    }
                    "stop" -> {
                        TaskTrackerService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun updateTaskWidget() {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(
            ComponentName(this, TaskWidgetProvider::class.java)
        )
        for (id in ids) {
            TaskWidgetProvider.updateWidget(this, manager, id)
        }
    }

    private fun updateNotifWidget() {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(
            ComponentName(this, NotificationWidgetProvider::class.java)
        )
        for (id in ids) {
            NotificationWidgetProvider.updateWidget(this, manager, id)
        }
    }
}
