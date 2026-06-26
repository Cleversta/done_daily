class DateUtils {
  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isRestDay(DateTime date) {
    // Sunday = 7
    return date.weekday == 7;
  }

  static Duration timeUntilWorkEnd(int workEndHour) {
    final now = DateTime.now();
    final workEnd = DateTime(now.year, now.month, now.day, workEndHour);
    
    if (workEnd.isBefore(now)) {
      return Duration.zero;
    }
    
    return workEnd.difference(now);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}min';
  }
}