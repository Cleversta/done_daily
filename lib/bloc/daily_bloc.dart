import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'daily_event.dart';
import 'daily_state.dart';
import '../models/daily_model.dart';
import '../models/goal_model.dart';
import '../models/settings_model.dart';
import '../models/recurring_goal.dart';

const _uuid = Uuid();

class DailyBloc extends Bloc<DailyEvent, DailyState> {
  late Box<Daily> _dailyBox;
  late Box<AppSettings> _settingsBox;
  late Box<RecurringGoal> _recurringBox;

  DailyBloc() : super(const DailyInitial()) {
    on<InitializeDailyEvent>(_onInitialize);
    on<LoadDailyEvent>(_onLoadDaily);
    on<AddGoalEvent>(_onAddGoal);
    on<EditGoalEvent>(_onEditGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
    on<CompleteGoalEvent>(_onCompleteGoal);
    on<UncompleteGoalEvent>(_onUncompleteGoal);
    on<TogglePriorityGoalEvent>(_onTogglePriority);
    on<ReorderGoalsEvent>(_onReorderGoals);
    on<SetWorkEndTimeEvent>(_onSetWorkEndTime);
    on<UpdateDailyNotesEvent>(_onUpdateNotes);
    on<CompleteWindDownEvent>(_onCompleteWindDown);
    on<SetRestDayEvent>(_onSetRestDay);
    on<LoadWeeklyArchiveEvent>(_onLoadWeeklyArchive);
    on<LoadMonthlyArchiveEvent>(_onLoadMonthlyArchive);
    on<ClearDailyEvent>(_onClearDaily);
    on<AddRecurringGoalEvent>(_onAddRecurringGoal);
    on<DeleteRecurringGoalEvent>(_onDeleteRecurringGoal);
    on<AcceptCarryoverEvent>(_onAcceptCarryover);
    on<DismissCarryoverEvent>(_onDismissCarryover);
    on<UpdateReflectionEvent>(_onUpdateReflection);
    on<UpdateArchiveReflectionEvent>(_onUpdateArchiveReflection);
  }

  AppSettings get _settings => _settingsBox.get('app_settings') ?? const AppSettings();

  List<RecurringGoal> get recurringGoals => _recurringBox.values.toList();

  Future<void> _onInitialize(InitializeDailyEvent event, Emitter<DailyState> emit) async {
    try {
      _dailyBox = await Hive.openBox<Daily>('daily');
      _settingsBox = await Hive.openBox<AppSettings>('settings');
      _recurringBox = await Hive.openBox<RecurringGoal>('recurring_goals');
      add(const LoadDailyEvent());
    } catch (e) {
      emit(DailyError('Failed to initialize: $e'));
    }
  }

  Future<void> _onLoadDaily(LoadDailyEvent event, Emitter<DailyState> emit) async {
    try {
      emit(const DailyLoading());
      final today = DateTime.now();
      final todayKey = _dateKey(today);
      final settings = _settings;

      Daily? daily = _dailyBox.get(todayKey);
      if (daily == null) {
        daily = Daily(
          id: todayKey,
          date: today,
          workEndHour: settings.workEndHour,
          workEndMinute: settings.workEndMinute,
          isRestDay: settings.restDays.contains(today.weekday),
        );
        await _dailyBox.put(todayKey, daily);
      }

      List<Goal> carryoverGoals = [];

      if (daily.goals.isEmpty) {
        // Seed recurring goals for today
        final templates = _recurringBox.values.where((t) => t.appliesOn(today.weekday));
        if (templates.isNotEmpty) {
          final seeded = templates.map((t) => Goal(
            id: _uuid.v4(),
            title: t.title,
            createdAt: DateTime.now(),
            isPriority: t.isPriority,
            recurringTemplateId: t.id,
          )).toList();
          daily = daily.copyWith(goals: seeded);
          await _dailyBox.put(todayKey, daily);
        }

        // Check yesterday for carry-over suggestions (incomplete, non-recurring goals only)
        final yesterday = today.subtract(const Duration(days: 1));
        final prevDaily = _dailyBox.get(_dateKey(yesterday));
        if (prevDaily != null) {
          carryoverGoals = prevDaily.goals
              .where((g) => !g.isCompleted && g.recurringTemplateId == null)
              .toList();
        }
      }

      emit(DailyLoaded(daily, streak: _calcStreak(today), carryoverGoals: carryoverGoals));
    } catch (e) {
      emit(DailyError('Failed to load daily: $e'));
    }
  }

  Future<void> _onAddGoal(AddGoalEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final goal = Goal(
      id: _uuid.v4(),
      title: event.title.trim(),
      createdAt: DateTime.now(),
      isPriority: event.isPriority,
      recurringTemplateId: event.recurringTemplateId,
    );
    final updated = current.copyWith(goals: [...current.goals, goal]);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onEditGoal(EditGoalEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(
      goals: current.goals.map((g) =>
        g.id == event.goalId ? g.copyWith(title: event.title.trim()) : g
      ).toList(),
    );
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onDeleteGoal(DeleteGoalEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(
      goals: current.goals.where((g) => g.id != event.goalId).toList(),
    );
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onCompleteGoal(CompleteGoalEvent event, Emitter<DailyState> emit) async {
    try {
      final current = _currentDaily(); if (current == null) return;
      final updated = current.copyWith(
        goals: current.goals.map((g) => g.id == event.goalId
          ? g.copyWith(isCompleted: true, completedAt: DateTime.now())
          : g).toList(),
      );
      await _save(updated);
      emit(GoalCompleted(updated, event.goalId, streak: _calcStreak(DateTime.now())));
    } catch (e) {
      emit(DailyError('Failed to complete goal: $e'));
    }
  }

  Future<void> _onUncompleteGoal(UncompleteGoalEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(
      goals: current.goals.map((g) => g.id == event.goalId
        ? g.copyWith(isCompleted: false, clearCompletedAt: true)
        : g).toList(),
    );
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onTogglePriority(TogglePriorityGoalEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(
      goals: current.goals.map((g) => g.id == event.goalId
        ? g.copyWith(isPriority: !g.isPriority)
        : g).toList(),
    );
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onReorderGoals(ReorderGoalsEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final goals = List<Goal>.from(current.goals);
    final item = goals.removeAt(event.oldIndex);
    final insertAt = event.newIndex > event.oldIndex ? event.newIndex - 1 : event.newIndex;
    goals.insert(insertAt, item);
    final updated = current.copyWith(goals: goals);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onSetWorkEndTime(SetWorkEndTimeEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(workEndHour: event.hour, workEndMinute: event.minute);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onUpdateNotes(UpdateDailyNotesEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(notes: event.notes);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onUpdateReflection(UpdateReflectionEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(reflection: event.text);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onUpdateArchiveReflection(UpdateArchiveReflectionEvent event, Emitter<DailyState> emit) async {
    final daily = _dailyBox.get(event.dailyId);
    if (daily == null) return;
    final updated = daily.copyWith(reflection: event.text);
    await _dailyBox.put(event.dailyId, updated);
    // Don't change the current DailyLoaded state — archive edits are background saves
  }

  Future<void> _onCompleteWindDown(CompleteWindDownEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(windDownCompleted: true);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onSetRestDay(SetRestDayEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final updated = current.copyWith(isRestDay: event.isRestDay);
    await _save(updated);
    if (event.isRestDay) {
      emit(RestDayActive(updated));
    } else {
      emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
    }
  }

  Future<void> _onLoadWeeklyArchive(LoadWeeklyArchiveEvent event, Emitter<DailyState> emit) async {
    try {
      emit(const DailyLoading());
      final today = DateTime.now();
      final weeklyData = <Daily>[];
      int completedDays = 0;

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final daily = _dailyBox.get(_dateKey(date));
        if (daily != null) {
          weeklyData.add(daily);
          if (daily.isRestDay || daily.completedGoalsCount > 0) completedDays++;
        }
      }

      emit(WeeklyArchiveLoaded(
        weeklyData: weeklyData,
        completedDays: completedDays,
        totalDays: 7,
        streak: _calcStreak(today),
      ));
    } catch (e) {
      emit(DailyError('Failed to load archive: $e'));
    }
  }

  Future<void> _onLoadMonthlyArchive(LoadMonthlyArchiveEvent event, Emitter<DailyState> emit) async {
    try {
      emit(const DailyLoading());
      final daysInMonth = DateTime(event.year, event.month + 1, 0).day;
      final monthlyData = <Daily>[];
      int completedDays = 0;

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(event.year, event.month, d);
        if (date.isAfter(DateTime.now())) break;
        final daily = _dailyBox.get(_dateKey(date));
        if (daily != null) {
          monthlyData.add(daily);
          if (daily.isRestDay || daily.completedGoalsCount > 0) completedDays++;
        }
      }

      emit(MonthlyArchiveLoaded(
        monthlyData: monthlyData,
        year: event.year,
        month: event.month,
        completedDays: completedDays,
        totalTrackedDays: monthlyData.length,
        streak: _calcStreak(DateTime.now()),
      ));
    } catch (e) {
      emit(DailyError('Failed to load monthly archive: $e'));
    }
  }

  Future<void> _onClearDaily(ClearDailyEvent event, Emitter<DailyState> emit) async {
    final today = DateTime.now();
    final key = _dateKey(today);
    final settings = _settings;
    final fresh = Daily(
      id: key,
      date: today,
      workEndHour: settings.workEndHour,
      workEndMinute: settings.workEndMinute,
      isRestDay: settings.restDays.contains(today.weekday),
    );
    await _dailyBox.put(key, fresh);
    emit(DailyLoaded(fresh, streak: 0));
  }

  // ── Recurring goal handlers ───────────────────────────────────────────────

  Future<void> _onAddRecurringGoal(AddRecurringGoalEvent event, Emitter<DailyState> emit) async {
    final template = RecurringGoal(
      id: _uuid.v4(),
      title: event.title.trim(),
      isPriority: event.isPriority,
      days: event.days,
    );
    await _recurringBox.put(template.id, template);
    // Also add to today if it applies
    final today = DateTime.now();
    if (template.appliesOn(today.weekday)) {
      final current = _currentDaily();
      if (current != null) {
        final alreadyHas = current.goals.any((g) => g.recurringTemplateId == template.id);
        if (!alreadyHas) {
          final goal = Goal(
            id: _uuid.v4(),
            title: template.title,
            createdAt: DateTime.now(),
            isPriority: template.isPriority,
            recurringTemplateId: template.id,
          );
          final updated = current.copyWith(goals: [...current.goals, goal]);
          await _save(updated);
          emit(DailyLoaded(updated, streak: _calcStreak(today)));
          return;
        }
      }
    }
    final current = _currentDaily();
    if (current != null) emit(DailyLoaded(current, streak: _calcStreak(today)));
  }

  Future<void> _onDeleteRecurringGoal(DeleteRecurringGoalEvent event, Emitter<DailyState> emit) async {
    await _recurringBox.delete(event.id);
    final current = _currentDaily();
    if (current != null) emit(DailyLoaded(current, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onAcceptCarryover(AcceptCarryoverEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    final newGoals = event.goals.map((g) => Goal(
      id: _uuid.v4(),
      title: g.title,
      createdAt: DateTime.now(),
      isPriority: g.isPriority,
    )).toList();
    final updated = current.copyWith(goals: [...current.goals, ...newGoals]);
    await _save(updated);
    emit(DailyLoaded(updated, streak: _calcStreak(DateTime.now())));
  }

  Future<void> _onDismissCarryover(DismissCarryoverEvent event, Emitter<DailyState> emit) async {
    final current = _currentDaily(); if (current == null) return;
    emit(DailyLoaded(current, streak: _calcStreak(DateTime.now())));
  }

  // ── Public habit streak calculator ───────────────────────────────────────

  /// Returns the number of consecutive completed days for a recurring habit
  /// identified by [templateId], iterating backwards through all stored dailies.
  /// Rest days are skipped (do not break the streak).
  /// Days where the template didn't apply (weekday not in template.days) are skipped.
  int habitStreak(String templateId) {
    final template = _recurringBox.get(templateId);
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final daily = _dailyBox.get(_dateKey(d));

      // No record for this day — stop
      if (daily == null) break;

      // Skip rest days — they don't break the streak
      if (daily.isRestDay) continue;

      // Skip days where the template doesn't apply (weekday not scheduled)
      if (template != null && !template.appliesOn(d.weekday)) continue;

      // Check if a goal with this template was present and completed
      final goal = daily.goals.where((g) => g.recurringTemplateId == templateId).firstOrNull;

      if (goal == null) {
        // Goal wasn't seeded that day — skip (could be before template was created)
        // If it's not today's index (i > 0), we stop since it means it wasn't tracked
        if (i > 0) break;
        continue;
      }

      if (goal.isCompleted) {
        streak++;
      } else {
        // Found an incomplete instance — streak ends
        break;
      }
    }

    return streak;
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Daily? _currentDaily() {
    final s = state;
    if (s is DailyLoaded) return s.daily;
    if (s is GoalCompleted) return s.daily;
    return null;
  }

  Future<void> _save(Daily daily) => _dailyBox.put(daily.id, daily);

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _calcStreak(DateTime from) {
    int streak = 0;
    var date = DateTime(from.year, from.month, from.day);

    // Count backwards until we hit a day with no data or an incomplete non-rest day
    for (int i = 0; i < 365; i++) {
      final d = date.subtract(Duration(days: i));
      final daily = _dailyBox.get(_dateKey(d));
      if (daily == null) break;
      if (daily.isRestDay || daily.completedGoalsCount > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
