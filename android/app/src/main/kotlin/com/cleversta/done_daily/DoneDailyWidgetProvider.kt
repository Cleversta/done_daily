package com.cleversta.done_daily

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

/**
 * Home-screen widget styled like the in-app DayTimeline hero card:
 * status pill · big countdown · next break · day progress · goals line.
 *
 * Data is written from Flutter via the home_widget plugin (GlanceService).
 * Remaining time / phase / day % are recomputed here on every update so the
 * countdown keeps ticking even when the Flutter app is not open.
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
        scheduleNextTick(context)
    }

    override fun onEnabled(context: Context) {
        scheduleNextTick(context)
    }

    override fun onDisabled(context: Context) {
        cancelTick(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DoneDailyWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                onUpdate(context, manager, ids)
            }
        }
    }

    companion object {
        private const val ACTION_TICK = "com.cleversta.done_daily.WIDGET_TICK"
        /** Refresh countdown more often than the 30-min system minimum. */
        private const val TICK_INTERVAL_MS = 15 * 60 * 1000L // 15 minutes

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData: SharedPreferences = HomeWidgetPlugin.getData(context)

            val goalsLeft = widgetData.getString("goalsLeft", "0")?.toIntOrNull() ?: 0
            val goalsTotal = widgetData.getString("goalsTotal", "0")?.toIntOrNull() ?: 0
            val isRestDay = widgetData.getString("isRestDay", "0") == "1"
            val nextBreak = widgetData.getString("nextBreakLabel", "") ?: ""
            val workStartHour = widgetData.getString("workStartHour", "8")?.toIntOrNull() ?: 8
            val workStartMinute = widgetData.getString("workStartMinute", "0")?.toIntOrNull() ?: 0
            val workEndHour = widgetData.getString("workEndHour", "18")?.toIntOrNull() ?: 18
            val workEndMinute = widgetData.getString("workEndMinute", "0")?.toIntOrNull() ?: 0

            val display = if (hasScheduleData(widgetData)) {
                computeDisplay(
                    goalsLeft = goalsLeft,
                    goalsTotal = goalsTotal,
                    isRestDay = isRestDay,
                    nextBreak = nextBreak,
                    workStartHour = workStartHour,
                    workStartMinute = workStartMinute,
                    workEndHour = workEndHour,
                    workEndMinute = workEndMinute
                )
            } else {
                // App has never written schedule data yet
                WidgetDisplay(
                    phase = "DONE:Daily",
                    countdown = "Open the app to refresh",
                    breakLine = "",
                    dayPct = 0,
                    goalsTitle = "No goals yet",
                    goalsFrac = "",
                    isSuccessPhase = false
                )
            }

            val views = RemoteViews(context.packageName, R.layout.done_daily_widget)

            // Phase badge
            views.setTextViewText(R.id.widget_phase, display.phase)
            views.setInt(
                R.id.widget_phase,
                "setBackgroundResource",
                if (display.isSuccessPhase) R.drawable.widget_badge_success_bg
                else R.drawable.widget_badge_bg
            )
            views.setTextColor(
                R.id.widget_phase,
                if (display.isSuccessPhase) 0xFF10B981.toInt() else 0xFF6366F1.toInt()
            )

            // Day %
            views.setTextViewText(R.id.widget_day_pct, "${display.dayPct}% of day")

            // Big countdown / status line (matches DayTimeline statusSub)
            views.setTextViewText(R.id.widget_countdown, display.countdown)

            // Next break
            if (display.breakLine.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_break, View.VISIBLE)
                views.setTextViewText(R.id.widget_break, display.breakLine)
            } else {
                views.setViewVisibility(R.id.widget_break, View.GONE)
            }

            // Day progress bar
            views.setProgressBar(R.id.widget_day_progress, 100, display.dayPct, false)

            // Goals row
            views.setTextViewText(R.id.widget_goals_title, display.goalsTitle)
            views.setTextViewText(R.id.widget_goals_frac, display.goalsFrac)

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

        private fun hasScheduleData(prefs: SharedPreferences): Boolean {
            return prefs.contains("workStartHour") || prefs.contains("workEndHour")
        }

        private data class WidgetDisplay(
            val phase: String,
            val countdown: String,
            val breakLine: String,
            val dayPct: Int,
            val goalsTitle: String,
            val goalsFrac: String,
            val isSuccessPhase: Boolean
        )

        /**
         * Recompute UI from wall-clock time so the widget stays live without the app.
         * Mirrors DayTimeline status strings and progress.
         */
        private fun computeDisplay(
            goalsLeft: Int,
            goalsTotal: Int,
            isRestDay: Boolean,
            nextBreak: String,
            workStartHour: Int,
            workStartMinute: Int,
            workEndHour: Int,
            workEndMinute: Int
        ): WidgetDisplay {
            if (isRestDay) {
                return WidgetDisplay(
                    phase = "Rest day",
                    countdown = "Take it easy today",
                    breakLine = "",
                    dayPct = 0,
                    goalsTitle = "Rest day",
                    goalsFrac = "",
                    isSuccessPhase = true
                )
            }

            val now = Calendar.getInstance()
            val start = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, workStartHour)
                set(Calendar.MINUTE, workStartMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val end = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, workEndHour)
                set(Calendar.MINUTE, workEndMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            // Overnight work window (end ≤ start) → end is next day
            if (!end.after(start)) {
                end.add(Calendar.DAY_OF_YEAR, 1)
            }

            val spanMs = (end.timeInMillis - start.timeInMillis).coerceAtLeast(1L)
            val elapsedMs = (now.timeInMillis - start.timeInMillis).coerceIn(0L, spanMs)
            val dayPct = ((elapsedMs * 100) / spanMs).toInt().coerceIn(0, 100)

            val phase: String
            val countdown: String
            val isSuccess: Boolean
            when {
                now.before(start) -> {
                    phase = "Before work"
                    countdown = formatRemaining(
                        start.timeInMillis - now.timeInMillis,
                        before = true
                    )
                    isSuccess = false
                }
                now.after(end) -> {
                    phase = "Day closed"
                    countdown = "Nice work — rest now"
                    isSuccess = true
                }
                else -> {
                    phase = "Working"
                    countdown = formatRemaining(
                        end.timeInMillis - now.timeInMillis,
                        before = false
                    )
                    isSuccess = false
                }
            }

            // Next break — Flutter already formats "Label HH:mm"; prefer a relative feel when possible
            val breakLine = if (nextBreak.isNotEmpty()) nextBreak else ""

            val goalsTitle: String
            val goalsFrac: String
            when {
                goalsTotal == 0 -> {
                    goalsTitle = "No goals yet"
                    goalsFrac = ""
                }
                goalsLeft == 0 -> {
                    goalsTitle = "All goals done"
                    goalsFrac = "$goalsTotal/$goalsTotal"
                }
                else -> {
                    goalsTitle = "$goalsLeft goal${if (goalsLeft == 1) "" else "s"} left"
                    goalsFrac = "${goalsTotal - goalsLeft}/$goalsTotal"
                }
            }

            return WidgetDisplay(
                phase = phase,
                countdown = countdown,
                breakLine = breakLine,
                dayPct = dayPct,
                goalsTitle = goalsTitle,
                goalsFrac = goalsFrac,
                isSuccessPhase = isSuccess
            )
        }

        /** Match DayTimeline wording: "Starts in Xh Ym" / "Xh Ym until end". */
        private fun formatRemaining(millis: Long, before: Boolean): String {
            if (millis <= 0) return if (before) "Starting soon" else "Ending soon"
            val totalMinutes = (millis / 60000).toInt()
            val h = totalMinutes / 60
            val m = totalMinutes % 60
            val body = when {
                h > 0 && m > 0 -> "${h}h ${m}m"
                h > 0 -> "${h}h"
                else -> "${m}m"
            }
            return if (before) "Starts in $body" else "$body until end"
        }

        private fun tickPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, DoneDailyWidgetProvider::class.java).apply {
                action = ACTION_TICK
            }
            return PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun scheduleNextTick(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = tickPendingIntent(context)
            alarmManager.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + TICK_INTERVAL_MS,
                TICK_INTERVAL_MS,
                pending
            )
        }

        fun cancelTick(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(tickPendingIntent(context))
        }
    }
}
