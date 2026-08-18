import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../models/custom_reminder.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _workEndId = 1;
  static const _morningId = 2;
  static const _weeklyId = 3;

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

  Future<void> scheduleMorningReminder(int hour, int minute) async {
    await _plugin.cancel(_morningId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _morningId,
      'Good morning',
      'Set your goals for today.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_reminder_v2',
          'Morning Reminder',
          channelDescription: 'Daily morning goal reminder',
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

    await _plugin.zonedSchedule(
      reminder.id,
      reminder.label,
      'Reminder from DONE:Daily.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'custom_reminder_v1',
          'Custom Reminders',
          channelDescription: 'Your own reminders during the day',
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

  // Re-schedules or cancels all notifications to match current settings.
  // Call on app startup (handles reboot clearing scheduled notifications) and on any settings change.
  Future<void> syncNotifications({
    required bool enabled,
    required bool workEndEnabled,
    required int workEndHour,
    required int workEndMinute,
    required bool morningEnabled,
    required int morningHour,
    required int morningMinute,
    bool weeklyEnabled = false,
    int weeklyHour = 20,
    int weeklyMinute = 0,
    List<CustomReminder> customReminders = const [],
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
    if (morningEnabled) {
      await scheduleMorningReminder(morningHour, morningMinute);
    } else {
      await cancelMorning();
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
  Future<void> cancelAll() => _plugin.cancelAll();
}
