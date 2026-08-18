import 'package:hive/hive.dart';
import 'custom_reminder.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 2)
class AppSettings {
  @HiveField(0)
  final int workEndHour;

  @HiveField(1)
  final int workEndMinute;

  @HiveField(2)
  final List<int> restDays;

  @HiveField(3)
  final bool notificationsEnabled;

  @HiveField(4)
  final int morningReminderHour;

  @HiveField(5)
  final int morningReminderMinute;

  @HiveField(6)
  final bool workEndNotificationEnabled;

  @HiveField(7)
  final bool morningReminderEnabled;

  @HiveField(8)
  final bool isDarkMode;

  @HiveField(9)
  final bool weeklyReminderEnabled;

  @HiveField(10)
  final int weeklyReminderHour;

  @HiveField(11)
  final int weeklyReminderMinute;

  @HiveField(12)
  final bool hasSeenOnboarding;

  /// User-defined reminders that sit between the morning and work-end ones.
  @HiveField(13)
  final List<CustomReminder> customReminders;

  const AppSettings({
    this.workEndHour = 18,
    this.workEndMinute = 0,
    this.restDays = const [7],
    this.notificationsEnabled = true,
    this.morningReminderHour = 8,
    this.morningReminderMinute = 0,
    this.workEndNotificationEnabled = true,
    this.morningReminderEnabled = true,
    this.isDarkMode = false,
    this.weeklyReminderEnabled = false,
    this.weeklyReminderHour = 20,
    this.weeklyReminderMinute = 0,
    this.hasSeenOnboarding = false,
    this.customReminders = const [],
  });

  AppSettings copyWith({
    int? workEndHour,
    int? workEndMinute,
    List<int>? restDays,
    bool? notificationsEnabled,
    int? morningReminderHour,
    int? morningReminderMinute,
    bool? workEndNotificationEnabled,
    bool? morningReminderEnabled,
    bool? isDarkMode,
    bool? weeklyReminderEnabled,
    int? weeklyReminderHour,
    int? weeklyReminderMinute,
    bool? hasSeenOnboarding,
    List<CustomReminder>? customReminders,
  }) {
    return AppSettings(
      workEndHour: workEndHour ?? this.workEndHour,
      workEndMinute: workEndMinute ?? this.workEndMinute,
      restDays: restDays ?? this.restDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      morningReminderHour: morningReminderHour ?? this.morningReminderHour,
      morningReminderMinute: morningReminderMinute ?? this.morningReminderMinute,
      workEndNotificationEnabled: workEndNotificationEnabled ?? this.workEndNotificationEnabled,
      morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      weeklyReminderEnabled: weeklyReminderEnabled ?? this.weeklyReminderEnabled,
      weeklyReminderHour: weeklyReminderHour ?? this.weeklyReminderHour,
      weeklyReminderMinute: weeklyReminderMinute ?? this.weeklyReminderMinute,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      customReminders: customReminders ?? this.customReminders,
    );
  }

  String get workEndDisplay {
    final h = workEndHour;
    final m = workEndMinute;
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$display:${m.toString().padLeft(2, '0')} $period';
  }

  String get morningReminderDisplay {
    final h = morningReminderHour;
    final m = morningReminderMinute;
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$display:${m.toString().padLeft(2, '0')} $period';
  }

  String get weeklyReminderDisplay {
    final h = weeklyReminderHour;
    final m = weeklyReminderMinute;
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$display:${m.toString().padLeft(2, '0')} $period';
  }
}
