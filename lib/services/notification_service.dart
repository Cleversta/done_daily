import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../models/custom_reminder.dart';
import '../models/settings_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _workEndId = 1;
  static const _morningId = 2; // prep before start (sound + text)
  static const _weeklyId = 3;
  static const _wrapUpId = 4;
  static const _workStartId = 5; // exact work start (text only)

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> scheduleWorkEndNotification(int hour, int minute) async {
    await _plugin.cancel(_workEndId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _workEndId,
      'Time to wind down',
      'Work is done. Close your tasks and rest.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'work_end_v2',
          'Work End Reminder',
          channelDescription: 'Notifies when work time ends',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notisong'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Prep / “plan your day” reminder — [minutesBefore] before work start
  /// (mirrors wrap-up, which is before work end).
  Future<void> scheduleMorningReminder({
    required int workStartHour,
    required int workStartMinute,
    required int minutesBefore,
  }) async {
    await _plugin.cancel(_morningId);
    if (minutesBefore <= 0) return;

    final startTotal = workStartHour * 60 + workStartMinute - minutesBefore;
    final normalized = ((startTotal % (24 * 60)) + (24 * 60)) % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Prep: sound + text (heads-up before the day starts)
    await _plugin.zonedSchedule(
      _morningId,
      'Plan your day',
      'About $minutesBefore minutes until work starts. Set a few goals.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prep_reminder_sound_v1',
          'Prep reminder',
          channelDescription: 'Sound + text before work start so you can plan the day',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notisong'),
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Exact work start — short ~2s chime (not the long 6s alert).
  Future<void> scheduleWorkStartNotification({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_workStartId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // New channel id so Android picks up the short sound (not the old silent channel).
    await _plugin.zonedSchedule(
      _workStartId,
      'Work has started',
      'Your work day is on. Focus on today’s goals.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'work_start_short_v1',
          'Work start',
          channelDescription: 'Short chime at work start',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          sound: RawResourceAndroidNotificationSound('notishort'),
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWeeklySummary(int hour, int minute) async {
    await _plugin.cancel(_weeklyId);
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    final daysUntilSunday = (DateTime.sunday - scheduled.weekday + 7) % 7;
    if (daysUntilSunday > 0) {
      scheduled = scheduled.add(Duration(days: daysUntilSunday));
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      _weeklyId,
      'Weekly recap',
      'Check how your week went — open DONE:Daily.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary_v2',
          'Weekly Summary',
          channelDescription: 'Sunday evening recap of your week',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          sound: RawResourceAndroidNotificationSound('notisong'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleCustomReminder(CustomReminder reminder) async {
    await _plugin.cancel(reminder.id);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = reminder.hasEnd
        ? 'Break until ${reminder.windowDisplay.split(' – ').last}. Step away and rest.'
        : 'Time for a break — from DONE:Daily.';

    await _plugin.zonedSchedule(
      reminder.id,
      reminder.label,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'custom_reminder_v1',
          'Breaks & reminders',
          channelDescription: 'Your break windows and custom reminders during the day',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          sound: RawResourceAndroidNotificationSound('notisong'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelCustomReminder(int id) => _plugin.cancel(id);

  // Schedules every enabled reminder and cancels the ones that were disabled
  // or deleted since the last sync.
  Future<void> syncCustomReminders(List<CustomReminder> reminders) async {
    final keep = <int>{};
    for (final reminder in reminders) {
      if (reminder.enabled) {
        keep.add(reminder.id);
        await scheduleCustomReminder(reminder);
      }
    }
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= CustomReminder.idBase && !keep.contains(request.id)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Fires [minutesBefore] before work end so the user can wrap up in time.
  Future<void> scheduleWrapUpNotification({
    required int workEndHour,
    required int workEndMinute,
    required int minutesBefore,
  }) async {
    await _plugin.cancel(_wrapUpId);
    if (minutesBefore <= 0) return;

    final endTotal = workEndHour * 60 + workEndMinute - minutesBefore;
    final normalized = ((endTotal % (24 * 60)) + (24 * 60)) % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Short chime (~2s) — same as work start; long sound reserved for prep / work end.
    await _plugin.zonedSchedule(
      _wrapUpId,
      'Wrap up soon',
      'About $minutesBefore minutes until work ends. Finish strong, then rest.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wrap_up_short_v1',
          'Wrap-up reminder',
          channelDescription: 'Short chime before work end so you can close the day on time',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notishort'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Re-schedules or cancels all notifications to match current settings.
  // Call on app startup (handles reboot clearing scheduled notifications) and on any settings change.
  Future<void> syncNotifications({
    required bool enabled,
    required bool workEndEnabled,
    required int workEndHour,
    required int workEndMinute,
    required bool morningEnabled,
    required int workStartHour,
    required int workStartMinute,
    int prepMinutesBefore = 15,
    bool weeklyEnabled = false,
    int weeklyHour = 20,
    int weeklyMinute = 0,
    List<CustomReminder> customReminders = const [],
    bool wrapUpEnabled = true,
    int wrapUpMinutesBefore = 15,
  }) async {
    if (!enabled) {
      await cancelAll();
      return;
    }
    if (workEndEnabled) {
      await scheduleWorkEndNotification(workEndHour, workEndMinute);
    } else {
      await cancelWorkEnd();
    }
    if (workEndEnabled && wrapUpEnabled && wrapUpMinutesBefore > 0) {
      await scheduleWrapUpNotification(
        workEndHour: workEndHour,
        workEndMinute: workEndMinute,
        minutesBefore: wrapUpMinutesBefore,
      );
    } else {
      await cancelWrapUp();
    }
    // Prep = sound + text, X min before work start
    if (morningEnabled && prepMinutesBefore > 0) {
      await scheduleMorningReminder(
        workStartHour: workStartHour,
        workStartMinute: workStartMinute,
        minutesBefore: prepMinutesBefore,
      );
    } else {
      await cancelMorning();
    }
    // Work start = short chime at the exact start time
    if (enabled) {
      await scheduleWorkStartNotification(
        hour: workStartHour,
        minute: workStartMinute,
      );
    } else {
      await cancelWorkStart();
    }
    if (weeklyEnabled) {
      await scheduleWeeklySummary(weeklyHour, weeklyMinute);
    } else {
      await cancelWeekly();
    }
    await syncCustomReminders(customReminders);
  }

  Future<void> cancelWorkEnd() => _plugin.cancel(_workEndId);
  Future<void> cancelMorning() => _plugin.cancel(_morningId);
  Future<void> cancelWeekly() => _plugin.cancel(_weeklyId);
  Future<void> cancelWrapUp() => _plugin.cancel(_wrapUpId);
  Future<void> cancelWorkStart() => _plugin.cancel(_workStartId);
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Convenience: schedule everything from an [AppSettings] snapshot.
  Future<void> syncFromSettings(AppSettings s) {
    return syncNotifications(
      enabled: s.notificationsEnabled,
      workEndEnabled: s.workEndNotificationEnabled,
      workEndHour: s.workEndHour,
      workEndMinute: s.workEndMinute,
      morningEnabled: s.morningReminderEnabled,
      workStartHour: s.workStartHour,
      workStartMinute: s.workStartMinute,
      prepMinutesBefore: s.prepMinutesBefore,
      weeklyEnabled: s.weeklyReminderEnabled,
      weeklyHour: s.weeklyReminderHour,
      weeklyMinute: s.weeklyReminderMinute,
      customReminders: s.customReminders,
      wrapUpEnabled: s.wrapUpEnabled,
      wrapUpMinutesBefore: s.wrapUpMinutesBefore,
    );
  }
}


