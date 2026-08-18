import 'package:hive/hive.dart';

class SupportCardService {
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox('support_flags');
  }

  static bool shouldShow(String trigger) {
    return _box?.get(trigger) != true;
  }

  static Future<void> markShown(String trigger) async {
    await _box?.put(trigger, true);
  }

  static const triggerWindDown = 'windDown';
  static const triggerStreak = 'streak7';
  static const triggerWeekly = 'weeklyProgress';
}
