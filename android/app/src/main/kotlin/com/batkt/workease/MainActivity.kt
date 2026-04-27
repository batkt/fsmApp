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
        
        // Explicitly register plugins to fix MissingPluginException
        io.flutter.plugins.GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Existing widget update channel
        println("[MainActivity] Registering WIDGET_CHANNEL: $WIDGET_CHANNEL")
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

        // Task tracker channel (deactivated as requested)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASK_TRACKER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start", "updateLiveProgress", "stop" -> {
                        // Service removed - only returning success to prevent Dart exceptions
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
