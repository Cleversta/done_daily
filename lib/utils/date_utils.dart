/// Shared date helpers for DONE:Daily.
/// Prefer these over ad-hoc formatting so keys and rest-day logic stay consistent.
class AppDateUtils {
  AppDateUtils._();

  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Whether [date] falls on a configured rest weekday (1 = Mon … 7 = Sun).
  static bool isConfiguredRestDay(DateTime date, List<int> restDays) {
    return restDays.contains(date.weekday);
  }

  static Duration timeUntilWorkEnd(int workEndHour, [int workEndMinute = 0]) {
    final now = DateTime.now();
    final workEnd = DateTime(now.year, now.month, now.day, workEndHour, workEndMinute);

    if (workEnd.isBefore(now) || workEnd.isAtSameMomentAs(now)) {
      return Duration.zero;
    }

    return workEnd.difference(now);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours <= 0) return '${minutes}min';
    return '${hours}h ${minutes}min';
  }
}
