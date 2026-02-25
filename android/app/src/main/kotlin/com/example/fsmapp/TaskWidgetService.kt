package com.example.fsmapp

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TaskWidgetFactory(applicationContext)
    }
}

class TaskWidgetFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    data class TaskItem(
        val index: Int,
        val title: String,
        val time: String,
        val status: Int // 0=pending, 1=inProgress, 2=completed
    )

    private var tasks = mutableListOf<TaskItem>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        tasks.clear()
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val total = try {
            prefs.getLong("flutter.widget_total_tasks", 0).toInt()
        } catch (_: Exception) { 0 }

        for (i in 1..total) {
            val title = try {
                prefs.getString("flutter.widget_task${i}_title", null)
            } catch (_: Exception) { null }

            if (title != null && title != "—") {
                val time = try {
                    prefs.getString("flutter.widget_task${i}_time", "") ?: ""
                } catch (_: Exception) { "" }

                val status = try {
                    prefs.getLong("flutter.widget_task${i}_status", 0).toInt()
                } catch (_: Exception) { 0 }

                tasks.add(TaskItem(i, title, time, status))
            }
        }
    }

    override fun onDestroy() { tasks.clear() }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_task_item)
        if (position >= tasks.size) return views

        val task = tasks[position]

        views.setTextViewText(R.id.taskItemTitle, task.title)
        views.setTextViewText(R.id.taskItemTime, task.time)

        // Status dot color
        val dotColor = when (task.status) {
            1 -> "#3B82F6"  // inProgress - blue
            2 -> "#10B981"  // completed - green
            else -> "#F59E0B" // pending - orange
        }
        views.setInt(R.id.taskItemDot, "setColorFilter", Color.parseColor(dotColor))

        // Button text and background
        when (task.status) {
            0 -> { // pending
                views.setTextViewText(R.id.taskItemStatus, "Эхлэх")
                views.setInt(R.id.taskItemStatus, "setBackgroundResource",
                    R.drawable.widget_btn_start)
            }
            1 -> { // inProgress
                views.setTextViewText(R.id.taskItemStatus, "Дуусгах")
                views.setInt(R.id.taskItemStatus, "setBackgroundResource",
                    R.drawable.widget_btn_finish)
            }
            2 -> { // completed
                views.setTextViewText(R.id.taskItemStatus, "✓")
                views.setInt(R.id.taskItemStatus, "setBackgroundResource",
                    R.drawable.widget_btn_done)
            }
        }

        // Fill in intent for click handling
        val fillIntent = Intent().apply {
            putExtra(TaskWidgetProvider.EXTRA_TASK_INDEX, task.index)
        }
        views.setOnClickFillInIntent(R.id.taskItemStatus, fillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
