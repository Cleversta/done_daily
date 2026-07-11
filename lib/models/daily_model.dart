import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'goal_model.dart';

part 'daily_model.g.dart';

@HiveType(typeId: 1)
class Daily extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<Goal> goals;

  @HiveField(3)
  final int workEndHour;

  @HiveField(4)
  final bool isRestDay;

  @HiveField(5)
  final bool windDownCompleted;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final int workEndMinute;

  @HiveField(8)
  final String reflection;

  @HiveField(9)
  final int focusMinutes;

  @HiveField(10)
  final String? tomorrowNote;

  Daily({
    required this.id,
    required this.date,
    this.goals = const [],
    this.workEndHour = 18,
    this.isRestDay = false,
    this.windDownCompleted = false,
    this.notes,
    this.workEndMinute = 0,
    this.reflection = '',
    this.focusMinutes = 0,
    this.tomorrowNote,
  });

  Daily copyWith({
    String? id,
    DateTime? date,
    List<Goal>? goals,
    int? workEndHour,
    int? workEndMinute,
    bool? isRestDay,
    bool? windDownCompleted,
    String? notes,
    String? reflection,
    int? focusMinutes,
    String? tomorrowNote,
  }) {
    return Daily(
      id: id ?? this.id,
      date: date ?? this.date,
      goals: goals ?? this.goals,
      workEndHour: workEndHour ?? this.workEndHour,
      workEndMinute: workEndMinute ?? this.workEndMinute,
      isRestDay: isRestDay ?? this.isRestDay,
      windDownCompleted: windDownCompleted ?? this.windDownCompleted,
      notes: notes ?? this.notes,
      reflection: reflection ?? this.reflection,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      tomorrowNote: tomorrowNote ?? this.tomorrowNote,
    );
  }

  int get completedGoalsCount => goals.where((g) => g.isCompleted).length;
  int get totalGoalsCount => goals.length;
  bool get allGoalsCompleted => goals.isNotEmpty && completedGoalsCount == totalGoalsCount;
  double get completionRatio => totalGoalsCount == 0 ? 0 : completedGoalsCount / totalGoalsCount;

  @override
  List<Object?> get props => [id, date, goals, workEndHour, workEndMinute, isRestDay, windDownCompleted, notes, reflection];
}
