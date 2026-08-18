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

  /// Break windows between work start and work end.
  @HiveField(13)
  final List<CustomReminder> customReminders;

  /// Start of the working day (day frame).
  @HiveField(14)
  final int workStartHour;

  @HiveField(15)
  final int workStartMinute;

  /// Notify this many minutes before work end (“wrap up soon”).
  @HiveField(16)
  final bool wrapUpEnabled;

  @HiveField(17)
  final int wrapUpMinutesBefore;

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
    this.workStartHour = 9,
    this.workStartMinute = 0,
    this.wrapUpEnabled = true,
    this.wrapUpMinutesBefore = 15,
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
    int? workStartHour,
    int? workStartMinute,
    bool? wrapUpEnabled,
    int? wrapUpMinutesBefore,
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
      workStartHour: workStartHour ?? this.workStartHour,
      workStartMinute: workStartMinute ?? this.workStartMinute,
      wrapUpEnabled: wrapUpEnabled ?? this.wrapUpEnabled,
      wrapUpMinutesBefore: wrapUpMinutesBefore ?? this.wrapUpMinutesBefore,
    );
  }

  static String _fmt(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$display:${m.toString().padLeft(2, '0')} $period';
  }

  String get workEndDisplay => _fmt(workEndHour, workEndMinute);
  String get workStartDisplay => _fmt(workStartHour, workStartMinute);
  String get morningReminderDisplay => _fmt(morningReminderHour, morningReminderMinute);
  String get weeklyReminderDisplay => _fmt(weeklyReminderHour, weeklyReminderMinute);

  int get workStartMinutes => workStartHour * 60 + workStartMinute;
  int get workEndMinutes => workEndHour * 60 + workEndMinute;

  /// Human label for the day frame, e.g. "9:00 AM – 6:00 PM".
  String get workWindowDisplay => '$workStartDisplay – $workEndDisplay';

  String get wrapUpDisplay {
    final total = workEndMinutes - wrapUpMinutesBefore;
    final h = ((total % (24 * 60)) + (24 * 60)) % (24 * 60) ~/ 60;
    final m = ((total % (24 * 60)) + (24 * 60)) % (24 * 60) % 60;
    return '${_fmt(h, m)} ($wrapUpMinutesBefore min before end)';
  }
}
