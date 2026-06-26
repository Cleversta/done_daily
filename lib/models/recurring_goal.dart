import 'package:hive/hive.dart';
part 'recurring_goal.g.dart';

@HiveType(typeId: 3)
class RecurringGoal {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final bool isPriority;
  @HiveField(3)
  final List<int> days; // 1=Mon..7=Sun; empty=every day

  RecurringGoal({
    required this.id,
    required this.title,
    this.isPriority = false,
    this.days = const [],
  });

  bool appliesOn(int weekday) => days.isEmpty || days.contains(weekday);

  String get daysLabel {
    if (days.isEmpty) return 'Every day';
    const names = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return days.map((d) => names[d]!).join(', ');
  }
}
