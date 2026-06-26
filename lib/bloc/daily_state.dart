import 'package:equatable/equatable.dart';
import '../models/daily_model.dart';
import '../models/goal_model.dart';

abstract class DailyState extends Equatable {
  const DailyState();

  @override
  List<Object?> get props => [];
}

class DailyInitial extends DailyState {
  const DailyInitial();
}

class DailyLoading extends DailyState {
  const DailyLoading();
}

class DailyLoaded extends DailyState {
  final Daily daily;
  final int streak;
  final List<Goal> carryoverGoals;

  const DailyLoaded(this.daily, {this.streak = 0, this.carryoverGoals = const []});

  @override
  List<Object?> get props => [daily, streak, carryoverGoals];
}

class GoalCompleted extends DailyState {
  final Daily daily;
  final String completedGoalId;
  final int streak;

  const GoalCompleted(this.daily, this.completedGoalId, {this.streak = 0});

  @override
  List<Object?> get props => [daily, completedGoalId, streak];
}

class WorkTimeReached extends DailyState {
  final Daily daily;

  const WorkTimeReached(this.daily);

  @override
  List<Object?> get props => [daily];
}

class RestDayActive extends DailyState {
  final Daily daily;

  const RestDayActive(this.daily);

  @override
  List<Object?> get props => [daily];
}

class WeeklyArchiveLoaded extends DailyState {
  final List<Daily> weeklyData;
  final int completedDays;
  final int totalDays;
  final int streak;

  const WeeklyArchiveLoaded({
    required this.weeklyData,
    required this.completedDays,
    required this.totalDays,
    required this.streak,
  });

  @override
  List<Object?> get props => [weeklyData, completedDays, totalDays, streak];
}

class MonthlyArchiveLoaded extends DailyState {
  final List<Daily> monthlyData;
  final int year;
  final int month;
  final int completedDays;
  final int totalTrackedDays;
  final int streak;

  const MonthlyArchiveLoaded({
    required this.monthlyData,
    required this.year,
    required this.month,
    required this.completedDays,
    required this.totalTrackedDays,
    required this.streak,
  });

  @override
  List<Object?> get props => [monthlyData, year, month, completedDays, totalTrackedDays, streak];
}

class DailyError extends DailyState {
  final String message;

  const DailyError(this.message);

  @override
  List<Object?> get props => [message];
}
