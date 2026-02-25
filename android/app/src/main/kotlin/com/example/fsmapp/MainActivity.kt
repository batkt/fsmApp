package com.example.fsmapp

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.fsmapp/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
