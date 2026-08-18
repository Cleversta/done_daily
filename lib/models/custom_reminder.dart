import 'package:hive/hive.dart';

part 'custom_reminder.g.dart';

/// A user-defined break / reminder that fires daily between the morning and
/// work-end reminders (e.g. "Lunch break" 12:00–13:00).
///
/// [hour]/[minute] is when the notification fires (break start).
/// [endHour]/[endMinute] is optional end of the break window for display.
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

  /// Optional break end hour (0–23). Null = point-in-time reminder only.
  @HiveField(5)
  final int? endHour;

  /// Optional break end minute (0–59).
  @HiveField(6)
  final int? endMinute;

  const CustomReminder({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.endHour,
    this.endMinute,
  });

  CustomReminder copyWith({
    int? id,
    String? label,
    int? hour,
    int? minute,
    bool? enabled,
    int? endHour,
    int? endMinute,
    bool clearEnd = false,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      endHour: clearEnd ? null : (endHour ?? this.endHour),
      endMinute: clearEnd ? null : (endMinute ?? this.endMinute),
    );
  }

  bool get hasEnd => endHour != null && endMinute != null;

  int get minutesOfDay => hour * 60 + minute;

  int? get endMinutesOfDay =>
      hasEnd ? endHour! * 60 + endMinute! : null;

  /// Duration of the break window, or null if no end is set.
  Duration? get duration {
    if (!hasEnd) return null;
    final start = minutesOfDay;
    var end = endMinutesOfDay!;
    if (end <= start) end += 24 * 60; // crosses midnight
    return Duration(minutes: end - start);
  }

  static String _fmtTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Start time only (e.g. "1:00 PM").
  String get timeDisplay => _fmtTime(hour, minute);

  /// "12:00 – 1:00 PM" when an end is set, otherwise just the start time.
  String get windowDisplay {
    if (!hasEnd) return timeDisplay;
    final samePeriod = (hour >= 12) == (endHour! >= 12);
    if (samePeriod) {
      // "12:00 – 1:00 PM"
      final startPeriod = hour >= 12 ? 'PM' : 'AM';
      final sh = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final eh = endHour == 0 ? 12 : (endHour! > 12 ? endHour! - 12 : endHour!);
      return '$sh:${minute.toString().padLeft(2, '0')} – $eh:${endMinute!.toString().padLeft(2, '0')} $startPeriod';
    }
    return '${_fmtTime(hour, minute)} – ${_fmtTime(endHour!, endMinute!)}';
  }

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
    if (endHour != null) 'endHour': endHour,
    if (endMinute != null) 'endMinute': endMinute,
  };

  static CustomReminder fromJson(Map<String, dynamic> j, {required int fallbackId}) {
    return CustomReminder(
      id: j['id'] as int? ?? fallbackId,
      label: j['label'] as String? ?? 'Break',
      hour: j['hour'] as int? ?? 12,
      minute: j['minute'] as int? ?? 0,
      enabled: j['enabled'] as bool? ?? true,
      endHour: j['endHour'] as int?,
      endMinute: j['endMinute'] as int?,
    );
  }
}
