package com.example.fsmapp

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class NotifWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NotifWidgetFactory(applicationContext)
    }
}

class NotifWidgetFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    data class NotifItem(
        val icon: String,
        val title: String,
        val body: String,
        val time: String
    )

    private var notifs = mutableListOf<NotifItem>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        notifs.clear()
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )

        val count = try {
            prefs.getLong("flutter.widget_notif_total", 6).toInt()
        } catch (_: Exception) { 6 }

        for (i in 1..count) {
            val title = try {
                prefs.getString("flutter.widget_notif${i}_title", null)
            } catch (_: Exception) { null }

            if (title != null) {
                val body = try {
                    prefs.getString("flutter.widget_notif${i}_body", "") ?: ""
                } catch (_: Exception) { "" }
                val icon = try {
                    prefs.getString("flutter.widget_notif${i}_icon", "📋") ?: "📋"
                } catch (_: Exception) { "📋" }
                val time = try {
                    prefs.getString("flutter.widget_notif${i}_time", "") ?: ""
                } catch (_: Exception) { "" }

                notifs.add(NotifItem(icon, title, body, time))
            }
        }
    }

    override fun onDestroy() { notifs.clear() }

    override fun getCount(): Int = notifs.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_notif_item)
        if (position >= notifs.size) return views

        val notif = notifs[position]

        views.setTextViewText(R.id.notifItemIcon, notif.icon)
        views.setTextViewText(R.id.notifItemTitle, notif.title)
        views.setTextViewText(R.id.notifItemBody, notif.body)
        views.setTextViewText(R.id.notifItemTime, notif.time)

        // Click opens app
        views.setOnClickFillInIntent(R.id.notifItemRoot, Intent())

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
