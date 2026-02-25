package com.example.fsmapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TaskWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_START = "com.example.fsmapp.ACTION_START"
        const val ACTION_FINISH = "com.example.fsmapp.ACTION_FINISH"
        const val ACTION_LIST_CLICK = "com.example.fsmapp.ACTION_LIST_CLICK"
        const val EXTRA_TASK_INDEX = "task_index"

        const val STATUS_PENDING = 0
        const val STATUS_IN_PROGRESS = 1
        const val STATUS_COMPLETED = 2

        fun refreshAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TaskWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, manager, id)
            }
            // Also notify data changed for ListView
            manager.notifyAppWidgetViewDataChanged(ids, R.id.widgetTaskList)
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_task)
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )

            val totalTasks = try {
                prefs.getLong("flutter.widget_total_tasks", 0).toInt()
            } catch (_: Exception) { 0 }
            val completedTasks = try {
                prefs.getLong("flutter.widget_completed_tasks", 0).toInt()
            } catch (_: Exception) { 0 }

            // Date
            val dateFormat = SimpleDateFormat("yyyy.MM.dd (EEE)", Locale.getDefault())
            views.setTextViewText(R.id.widgetDate, dateFormat.format(Date()))

            // Progress
            val progress = if (totalTasks > 0) (completedTasks * 100 / totalTasks) else 0
            views.setTextViewText(R.id.widgetProgressText, "$completedTasks/$totalTasks")
            views.setProgressBar(R.id.widgetProgressBar, 100, progress, false)

            // Open app when tapping header
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPending = PendingIntent.getActivity(
                context, 100, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, openAppPending)

            // Setup ListView adapter
            val serviceIntent = Intent(context, TaskWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widgetTaskList, serviceIntent)

            // Template for list item clicks (Start/Finish buttons)
            val clickIntent = Intent(context, TaskWidgetProvider::class.java).apply {
                action = ACTION_LIST_CLICK
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val clickPending = PendingIntent.getBroadcast(
                context, 400,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.widgetTaskList, clickPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widgetTaskList)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_LIST_CLICK -> {
                val taskIndex = intent.getIntExtra(EXTRA_TASK_INDEX, -1)
                if (taskIndex > 0) {
                    // Read current status and advance it
                    val prefs = context.getSharedPreferences(
                        "FlutterSharedPreferences", Context.MODE_PRIVATE
                    )
                    val currentStatus = try {
                        prefs.getLong("flutter.widget_task${taskIndex}_status", 0).toInt()
                    } catch (_: Exception) { 0 }

                    val newStatus = when (currentStatus) {
                        STATUS_PENDING -> STATUS_IN_PROGRESS
                        STATUS_IN_PROGRESS -> STATUS_COMPLETED
                        else -> return // already completed, no action
                    }
                    changeTaskStatus(context, taskIndex, newStatus)
                }
            }
            ACTION_START -> {
                val taskIndex = intent.getIntExtra(EXTRA_TASK_INDEX, -1)
                if (taskIndex > 0) changeTaskStatus(context, taskIndex, STATUS_IN_PROGRESS)
            }
            ACTION_FINISH -> {
                val taskIndex = intent.getIntExtra(EXTRA_TASK_INDEX, -1)
                if (taskIndex > 0) changeTaskStatus(context, taskIndex, STATUS_COMPLETED)
            }
        }
    }

    private fun changeTaskStatus(context: Context, taskIndex: Int, newStatus: Int) {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )

        prefs.edit().putLong("flutter.widget_task${taskIndex}_status", newStatus.toLong()).apply()

        // Recalculate completed count
        val total = try {
            prefs.getLong("flutter.widget_total_tasks", 8).toInt()
        } catch (_: Exception) { 8 }

        var completed = 0
        for (i in 1..total) {
            val s = try {
                prefs.getLong("flutter.widget_task${i}_status", 0).toInt()
            } catch (_: Exception) { 0 }
            if (s == STATUS_COMPLETED) completed++
        }
        prefs.edit().putLong("flutter.widget_completed_tasks", completed.toLong()).apply()

        refreshAllWidgets(context)
    }
}
