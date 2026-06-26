import 'package:equatable/equatable.dart';
import '../models/goal_model.dart';

abstract class DailyEvent extends Equatable {
  const DailyEvent();

  @override
  List<Object?> get props => [];
}

class InitializeDailyEvent extends DailyEvent {
  const InitializeDailyEvent();
}

class LoadDailyEvent extends DailyEvent {
  const LoadDailyEvent();
}

class AddGoalEvent extends DailyEvent {
  final String title;
  final bool isPriority;
  final String? recurringTemplateId;

  const AddGoalEvent(this.title, {this.isPriority = false, this.recurringTemplateId});

  @override
  List<Object?> get props => [title, isPriority, recurringTemplateId];
}

class EditGoalEvent extends DailyEvent {
  final String goalId;
  final String title;

  const EditGoalEvent({required this.goalId, required this.title});

  @override
  List<Object?> get props => [goalId, title];
}

class DeleteGoalEvent extends DailyEvent {
  final String goalId;

  const DeleteGoalEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class CompleteGoalEvent extends DailyEvent {
  final String goalId;

  const CompleteGoalEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class UncompleteGoalEvent extends DailyEvent {
  final String goalId;

  const UncompleteGoalEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class TogglePriorityGoalEvent extends DailyEvent {
  final String goalId;

  const TogglePriorityGoalEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class ReorderGoalsEvent extends DailyEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderGoalsEvent({required this.oldIndex, required this.newIndex});

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SetWorkEndTimeEvent extends DailyEvent {
  final int hour;
  final int minute;

  const SetWorkEndTimeEvent({required this.hour, this.minute = 0});

  @override
  List<Object?> get props => [hour, minute];
}

class UpdateDailyNotesEvent extends DailyEvent {
  final String notes;

  const UpdateDailyNotesEvent(this.notes);

  @override
  List<Object?> get props => [notes];
}

class CompleteWindDownEvent extends DailyEvent {
  const CompleteWindDownEvent();
}

class SetRestDayEvent extends DailyEvent {
  final bool isRestDay;

  const SetRestDayEvent(this.isRestDay);

  @override
  List<Object?> get props => [isRestDay];
}

class LoadWeeklyArchiveEvent extends DailyEvent {
  const LoadWeeklyArchiveEvent();
}

class LoadMonthlyArchiveEvent extends DailyEvent {
  final int year;
  final int month;

  const LoadMonthlyArchiveEvent({required this.year, required this.month});

  @override
  List<Object?> get props => [year, month];
}

class ClearDailyEvent extends DailyEvent {
  const ClearDailyEvent();
}

// ─── Recurring goal events ────────────────────────────────────────────────────

class AddRecurringGoalEvent extends DailyEvent {
  final String title;
  final bool isPriority;
  final List<int> days;
  const AddRecurringGoalEvent({
    required this.title,
    this.isPriority = false,
    this.days = const [],
  });
  @override
  List<Object?> get props => [title, isPriority, days];
}

class DeleteRecurringGoalEvent extends DailyEvent {
  final String id;
  const DeleteRecurringGoalEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// ─── Carryover events ─────────────────────────────────────────────────────────

class AcceptCarryoverEvent extends DailyEvent {
  final List<Goal> goals;
  const AcceptCarryoverEvent(this.goals);
  @override
  List<Object?> get props => [goals];
}

class DismissCarryoverEvent extends DailyEvent {
  const DismissCarryoverEvent();
}

class UpdateReflectionEvent extends DailyEvent {
  final String text;
  const UpdateReflectionEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class UpdateArchiveReflectionEvent extends DailyEvent {
  final String dailyId;
  final String text;
  const UpdateArchiveReflectionEvent({required this.dailyId, required this.text});
  @override
  List<Object?> get props => [dailyId, text];
}
