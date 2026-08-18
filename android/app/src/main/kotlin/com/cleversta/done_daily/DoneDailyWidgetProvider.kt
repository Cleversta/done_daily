package com.cleversta.done_daily

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen widget showing goals left, time until work end, and next break.
 * Data is written from Flutter via the home_widget plugin (GlanceService).
 */
class DoneDailyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun onEnabled(context: Context) {
        // First widget instance added — Flutter will push data on next app open.
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData: SharedPreferences = HomeWidgetPlugin.getData(context)
            val title = widgetData.getString("title", "DONE:Daily") ?: "DONE:Daily"
            val summary = widgetData.getString("summaryLine", "Open the app to refresh")
                ?: "Open the app to refresh"
            val phase = widgetData.getString("phaseLabel", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.done_daily_widget)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_summary, summary)
            views.setTextViewText(R.id.widget_phase, phase)

            // Tap opens the app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
