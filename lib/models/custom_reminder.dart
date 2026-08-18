import 'package:hive/hive.dart';

part 'custom_reminder.g.dart';

/// A user-defined reminder that fires daily between the morning and work-end
/// reminders (e.g. "Lunch break", "Stretch").
@HiveType(typeId: 4)
class CustomReminder {
  /// Notification ids for custom reminders start here so they never collide
  /// with the fixed work-end/morning/weekly ids.
  static const int idBase = 100;

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final int hour;

  @HiveField(3)
  final int minute;

  @HiveField(4)
  final bool enabled;

  const CustomReminder({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  CustomReminder copyWith({
    int? id,
    String? label,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  String get timeDisplay {
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:${minute.toString().padLeft(2, '0')} $period';
  }

  int get minutesOfDay => hour * 60 + minute;

  /// Next free notification id for a new reminder.
  static int nextId(List<CustomReminder> existing) {
    final used = existing.map((r) => r.id);
    return used.isEmpty ? idBase : used.reduce((a, b) => a > b ? a : b) + 1;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
  };

  static CustomReminder fromJson(Map<String, dynamic> j, {required int fallbackId}) {
    return CustomReminder(
      id: j['id'] as int? ?? fallbackId,
      label: j['label'] as String? ?? 'Reminder',
      hour: j['hour'] as int? ?? 12,
      minute: j['minute'] as int? ?? 0,
      enabled: j['enabled'] as bool? ?? true,
    );
  }
}
