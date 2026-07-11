import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../bloc/daily_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../models/daily_model.dart';
import '../models/goal_model.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

enum _ReminderType { morning, workEnd }

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return BlocBuilder<DailyBloc, DailyState>(
      builder: (context, state) {
        if (state is DailyLoading || state is DailyInitial ||
            state is WeeklyArchiveLoaded || state is MonthlyArchiveLoaded) {
          return Scaffold(
            backgroundColor: t.background,
            body: Center(child: CircularProgressIndicator(color: t.textPrimary)),
          );
        }
        if (state is RestDayActive) return _RestDayView(daily: state.daily);
        if (state is DailyError) {
          return Scaffold(
            backgroundColor: t.background,
            body: Center(child: Text('Error: ${state.message}', style: TextStyle(color: AppColors.danger))),
          );
        }
        if (state is! DailyLoaded && state is! GoalCompleted) {
          return Scaffold(
            backgroundColor: t.background,
            body: Center(child: CircularProgressIndicator(color: t.textPrimary)),
          );
        }

        final daily = state is DailyLoaded ? state.daily : (state as GoalCompleted).daily;
        final streak = state is DailyLoaded ? state.streak : (state as GoalCompleted).streak;
        return _DashboardView(daily: daily, streak: streak, state: state);
      },
    );
  }
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

class _DashboardView extends StatefulWidget {
  final Daily daily;
  final int streak;
  final DailyState state;

  const _DashboardView({required this.daily, required this.streak, required this.state});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> with WidgetsBindingObserver {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final daily = widget.daily;
    final streak = widget.streak;
    final state = widget.state;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final now = _now;
    var workEnd = DateTime(now.year, now.month, now.day, daily.workEndHour, daily.workEndMinute);
    // If work end is >12h in the past, the shift crosses midnight — target tomorrow's 1am
    if (now.difference(workEnd).inHours > 12) {
      workEnd = workEnd.add(const Duration(days: 1));
    }
    final remaining = workEnd.difference(now);
    final isDone = remaining.isNegative;

    final greeting = _greeting(now.hour);

    return Scaffold(
      backgroundColor: t.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM d').format(daily.date),
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(now),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                      ),
                      if (streak > 0) ...[
                        const SizedBox(height: 4),
                        _StreakBadge(streak: streak),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Reminder chips
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ReminderBar(onPickTime: (type) => _pickReminderTime(context, type)),
            ),

            // Progress bar
            if (daily.totalGoalsCount > 0) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ProgressBar(daily: daily),
              ),
            ],

            const SizedBox(height: 14),

            // Carryover banner
            if (state is DailyLoaded && state.carryoverGoals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _CarryoverBanner(goals: state.carryoverGoals),
              ),

            // Reflection card
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: _ReflectionCard(savedText: daily.reflection),
            ),

            // Goals section header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Row(
                children: [
                  Text(
                    "TODAY'S GOALS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: t.textTertiary.withValues(alpha: 0.2), height: 1)),
                  if (daily.totalGoalsCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${daily.completedGoalsCount}/${daily.totalGoalsCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: daily.allGoalsCompleted ? t.success : t.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Goal list
            Expanded(
              child: daily.goals.isEmpty
                  ? _EmptyState(onAdd: () => _showAddSheet(context))
                  : _GoalList(daily: daily),
            ),

            // Recurring indicator
            BlocBuilder<DailyBloc, DailyState>(
              builder: (context, _) {
                final count = context.read<DailyBloc>().recurringGoals.length;
                if (count == 0) return const SizedBox.shrink();
                final t2 = NTheme.of(context);
                return GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<DailyBloc>(),
                      child: const _RecurringGoalsSheet(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.repeat_rounded, size: 12, color: t2.accent),
                      const SizedBox(width: 4),
                      Text(
                        '$count recurring goal${count > 1 ? 's' : ''} — tap to manage',
                        style: TextStyle(fontSize: 11, color: t2.accent),
                      ),
                    ]),
                  ),
                );
              },
            ),

            // Work-ends card + Add button — hidden while keyboard is open
            if (!keyboardOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    _WorkEndCard(
                      daily: daily,
                      isDone: isDone,
                      remaining: remaining,
                      onTap: () => _pickWorkEndTime(context, daily),
                      onWindDown: () => context.pushNamed('winddown', extra: {'daily': daily}),
                    ),
                    const SizedBox(height: 12),
                    _AddGoalButton(onTap: () => _showAddSheet(context)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _pickReminderTime(BuildContext context, _ReminderType type) async {
    final settingsBloc = context.read<SettingsBloc>();
    final settings = settingsBloc.current;
    final initial = type == _ReminderType.morning
        ? TimeOfDay(hour: settings.morningReminderHour, minute: settings.morningReminderMinute)
        : TimeOfDay(hour: settings.workEndHour, minute: settings.workEndMinute);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.textPrimary,
            onPrimary: AppColors.background,
            surface: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;

    if (type == _ReminderType.morning) {
      final updated = settings.copyWith(morningReminderHour: picked.hour, morningReminderMinute: picked.minute);
      settingsBloc.add(UpdateSettingsEvent(updated));
      if (settings.notificationsEnabled && settings.morningReminderEnabled) {
        await NotificationService.instance.scheduleMorningReminder(picked.hour, picked.minute);
      }
    } else {
      final updated = settings.copyWith(workEndHour: picked.hour, workEndMinute: picked.minute);
      settingsBloc.add(UpdateSettingsEvent(updated));
      if (settings.notificationsEnabled && settings.workEndNotificationEnabled) {
        await NotificationService.instance.scheduleWorkEndNotification(picked.hour, picked.minute);
      }
    }
  }

  Future<void> _pickWorkEndTime(BuildContext context, Daily daily) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: daily.workEndHour, minute: daily.workEndMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.textPrimary,
            onPrimary: AppColors.background,
            surface: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    context.read<DailyBloc>().add(SetWorkEndTimeEvent(hour: picked.hour, minute: picked.minute));
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<DailyBloc>(),
        child: const _AddGoalSheet(),
      ),
    );
  }
}

// ─── Reflection card ──────────────────────────────────────────────────────────

class _ReflectionCard extends StatefulWidget {
  final String savedText;
  const _ReflectionCard({required this.savedText});

  @override
  State<_ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<_ReflectionCard> {
  late TextEditingController _controller;
  late String _savedText;

  @override
  void initState() {
    super.initState();
    _savedText = widget.savedText;
    _controller = TextEditingController(text: _savedText);
  }

  @override
  void didUpdateWidget(_ReflectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New day loaded — sync to the fresh saved text
    if (oldWidget.savedText != widget.savedText && _savedText == oldWidget.savedText) {
      _savedText = widget.savedText;
      _controller.text = _savedText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDirty => _controller.text != _savedText;

  void _save() {
    final text = _controller.text;
    context.read<DailyBloc>().add(UpdateReflectionEvent(text));
    setState(() => _savedText = text);
    FocusScope.of(context).unfocus();
  }

  void _discard() {
    _controller.text = _savedText;
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(t.accent.withValues(alpha: 0.06), t.surface),
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.subtleShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 18, color: t.accent),
          const SizedBox(width: 10),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 60),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 13, color: t.textPrimary, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'How was your day?',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintStyle: TextStyle(color: t.textTertiary, fontSize: 13),
                ),
              ),
            ),
          ),
          if (_isDirty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _discard,
              child: Text('Cancel', style: TextStyle(fontSize: 11, color: t.textTertiary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Carryover banner ─────────────────────────────────────────────────────────

class _CarryoverBanner extends StatelessWidget {
  final List<Goal> goals;
  const _CarryoverBanner({required this.goals});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
        border: Border.all(color: t.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: t.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${goals.length} incomplete goal${goals.length > 1 ? 's' : ''} from yesterday',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.textSecondary),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<DailyBloc>().add(AcceptCarryoverEvent(goals)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: t.buttonShadow,
              ),
              child: Text(
                'Add',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.read<DailyBloc>().add(const DismissCarryoverEvent()),
            child: Icon(Icons.close_rounded, size: 16, color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final Daily daily;
  const _ProgressBar({required this.daily});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final ratio = daily.completionRatio;
    final pct = (ratio * 100).round();
    final barColor = daily.allGoalsCompleted ? t.success : t.accent;
    return Row(
      children: [
        // Big percentage
        SizedBox(
          width: 52,
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: daily.allGoalsCompleted ? t.success : t.textPrimary,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: t.shadowDark.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                daily.allGoalsCompleted
                    ? 'All done — great work!'
                    : '${daily.completedGoalsCount} of ${daily.totalGoalsCount} goals done',
                style: TextStyle(fontSize: 11, color: t.textTertiary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Streak badge ─────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: t.buttonShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Goal list ────────────────────────────────────────────────────────────────

class _GoalList extends StatelessWidget {
  final Daily daily;
  const _GoalList({required this.daily});

  @override
  Widget build(BuildContext context) {
    final sorted = [
      ...daily.goals.where((g) => g.isPriority && !g.isCompleted),
      ...daily.goals.where((g) => !g.isPriority && !g.isCompleted),
      ...daily.goals.where((g) => g.isCompleted),
    ];

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: sorted.length,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.lightImpact();
        context.read<DailyBloc>().add(
          ReorderGoalsEvent(oldIndex: oldIndex, newIndex: newIndex),
        );
      },
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: child,
      ),
      itemBuilder: (context, index) {
        final goal = sorted[index];
        return _GoalTile(key: ValueKey(goal.id), goal: goal);
      },
    );
  }
}

// ─── Goal tile ────────────────────────────────────────────────────────────────

class _GoalTile extends StatelessWidget {
  final Goal goal;
  const _GoalTile({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('dismiss_${goal.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.large),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
        ),
        confirmDismiss: (_) async {
          HapticFeedback.mediumImpact();
          return await _confirmDelete(context);
        },
        onDismissed: (_) {
          context.read<DailyBloc>().add(DeleteGoalEvent(goal.id));
        },
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showEditSheet(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: (!goal.isCompleted && goal.isPriority)
                  ? AppColors.warning.withValues(alpha: 0.07)
                  : t.surface,
              borderRadius: BorderRadius.circular(AppRadii.large),
              boxShadow: goal.isCompleted ? t.insetShadow : t.boxShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: title + checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (goal.recurringTemplateId != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 5, top: 1),
                        child: Icon(Icons.repeat_rounded, size: 14, color: t.accent),
                      ),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: goal.isCompleted ? t.textTertiary : t.textPrimary,
                          decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: t.textTertiary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Checkbox — only this marks done
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (goal.isCompleted) {
                          context.read<DailyBloc>().add(UncompleteGoalEvent(goal.id));
                        } else {
                          context.read<DailyBloc>().add(CompleteGoalEvent(goal.id));
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: goal.isCompleted ? AppColors.success : t.surface,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: goal.isCompleted ? t.insetShadow : t.buttonShadow,
                          border: goal.isCompleted
                              ? null
                              : Border.all(color: t.textTertiary.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Center(
                          child: Icon(
                            goal.isCompleted ? Icons.check_rounded : null,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 2: actions
                Row(
                  children: [
                    // Priority star
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<DailyBloc>().add(TogglePriorityGoalEvent(goal.id));
                      },
                      child: Row(
                        children: [
                          Icon(
                            goal.isPriority ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 20,
                            color: goal.isPriority ? AppColors.warning : t.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 12,
                              color: goal.isPriority ? t.textSecondary : t.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Focus / timer button
                    if (!goal.isCompleted)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final bloc = context.read<DailyBloc>();
                          final s = bloc.state;
                          context.pushNamed('focus', extra: {
                            'goal': goal,
                            'daily': s is DailyLoaded
                                ? s.daily
                                : (s as GoalCompleted).daily,
                          });
                        },
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 20, color: t.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Timer',
                              style: TextStyle(fontSize: 12, color: t.textTertiary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    // Drag handle
                    Icon(Icons.drag_handle_rounded, size: 20, color: t.textTertiary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('"${goal.title}" will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<DailyBloc>(),
        child: _EditGoalSheet(goal: goal),
      ),
    );
  }
}

// ─── Work end card ────────────────────────────────────────────────────────────

class _WorkEndCard extends StatelessWidget {
  final Daily daily;
  final bool isDone;
  final Duration remaining;
  final VoidCallback onTap;
  final VoidCallback onWindDown;

  const _WorkEndCard({
    required this.daily,
    required this.isDone,
    required this.remaining,
    required this.onTap,
    required this.onWindDown,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final h = daily.workEndHour;
    final m = daily.workEndMinute;
    final period = h >= 12 ? 'PM' : 'AM';
    final dispH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final timeStr = '$dispH:${m.toString().padLeft(2, '0')} $period';

    return Container(
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success.withValues(alpha: 0.09)
            : t.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: isDone ? t.insetShadow : t.boxShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle_outline_rounded : Icons.schedule_outlined,
                      size: 20,
                      color: isDone ? AppColors.success : t.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDone ? 'Work done ✓' : 'Work ends at $timeStr',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            isDone
                                ? 'Tap the moon to wind down'
                                : '${remaining.inHours}h ${remaining.inMinutes % 60}min remaining — tap to edit',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: t.shadowDark.withValues(alpha: 0.08),
          ),

          // Right: wind-down button
          GestureDetector(
            onTap: onWindDown,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.nightlight_round_outlined,
                    size: 22,
                    color: isDone ? t.accent : t.textTertiary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wind\nDown',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDone ? t.accent : t.textTertiary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add goal button ──────────────────────────────────────────────────────────

class _AddGoalButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGoalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(AppRadii.large),
          boxShadow: [
            BoxShadow(
              color: t.accent.withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Add Goal',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_box_outline_blank_rounded, size: 32, color: t.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            'No goals yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + Add Goal to start your day',
            style: TextStyle(fontSize: 12, color: t.textTertiary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ─── Add goal bottom sheet ────────────────────────────────────────────────────

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();
  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _controller = TextEditingController();
  bool _isPriority = false;
  bool _isRecurring = false;
  List<int> _repeatDays = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_isRecurring) {
      context.read<DailyBloc>().add(AddRecurringGoalEvent(
        title: text,
        isPriority: _isPriority,
        days: List.from(_repeatDays),
      ));
    } else {
      context.read<DailyBloc>().add(AddGoalEvent(text, isPriority: _isPriority));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(AppRadii.extraLarge),
          boxShadow: t.boxShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Goal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: 'What do you want to finish?'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isPriority = !_isPriority),
                  child: Row(
                    children: [
                      Icon(
                        _isPriority ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 20,
                        color: _isPriority ? AppColors.warning : t.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isPriority ? t.textPrimary : t.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => setState(() {
                    _isRecurring = !_isRecurring;
                    if (!_isRecurring) _repeatDays = [];
                  }),
                  child: Row(children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 20,
                      color: _isRecurring ? t.accent : t.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Repeat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _isRecurring ? t.textPrimary : t.textTertiary,
                      ),
                    ),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: t.buttonShadow,
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 13, color: t.textTertiary)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: t.buttonShadow,
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                  const names = {1: 'Mo', 2: 'Tu', 3: 'We', 4: 'Th', 5: 'Fr', 6: 'Sa', 7: 'Su'};
                  final selected = _repeatDays.contains(day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? _repeatDays.remove(day) : _repeatDays.add(day);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        boxShadow: selected ? t.insetShadow : t.buttonShadow,
                      ),
                      child: Text(
                        names[day]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? t.accent : t.textTertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Leave empty = every day',
                  style: TextStyle(fontSize: 10, color: t.textTertiary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Edit goal bottom sheet ───────────────────────────────────────────────────

class _EditGoalSheet extends StatefulWidget {
  final Goal goal;
  const _EditGoalSheet({required this.goal});
  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.goal.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<DailyBloc>().add(EditGoalEvent(goalId: widget.goal.id, title: text));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(AppRadii.extraLarge),
          boxShadow: t.boxShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Goal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: 'Goal title'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: t.buttonShadow,
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 13, color: t.textTertiary)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: t.buttonShadow,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rest day view ────────────────────────────────────────────────────────────

class _RestDayView extends StatelessWidget {
  final Daily daily;
  const _RestDayView({required this.daily});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: t.surface,
                    shape: BoxShape.circle,
                    boxShadow: t.boxShadow,
                  ),
                  child: Center(
                    child: Text('∞', style: TextStyle(fontSize: 40, color: t.textSecondary)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Rest day', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'This app won\'t bug you today.\nJust enjoy your day.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => context.read<DailyBloc>().add(const SetRestDayEvent(false)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: t.buttonShadow,
                    ),
                    child: Text('Work today instead', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recurring goals sheet ────────────────────────────────────────────────────

class _RecurringGoalsSheet extends StatelessWidget {
  const _RecurringGoalsSheet();

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final bloc = context.read<DailyBloc>();
    final templates = bloc.recurringGoals;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(AppRadii.extraLarge),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recurring Goals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 12),
          if (templates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recurring goals yet.\nAdd a goal and enable "Repeat" to create one.',
                style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.5),
              ),
            )
          else
            ...templates.map((template) {
              final streak = bloc.habitStreak(template.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.repeat_rounded, size: 16, color: t.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.title,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.textPrimary),
                              ),
                            ),
                            if (streak > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: t.surface,
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                  boxShadow: t.buttonShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$streak',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(template.daysLabel, style: TextStyle(fontSize: 11, color: t.textTertiary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      bloc.add(DeleteRecurringGoalEvent(template.id));
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.delete_outline_rounded, size: 18, color: t.danger),
                  ),
                ]),
              );
            }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Text('Close', style: TextStyle(fontSize: 13, color: t.textTertiary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reminder bar ─────────────────────────────────────────────────────────────

class _ReminderBar extends StatelessWidget {
  final void Function(_ReminderType) onPickTime;
  const _ReminderBar({required this.onPickTime});

  String _fmt(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final s = state is SettingsLoaded ? state.settings : const AppSettings();
        final t = NTheme.of(context);
        return Row(
          children: [
            _ReminderChip(
              icon: Icons.wb_sunny_outlined,
              label: 'Morning',
              time: _fmt(s.morningReminderHour, s.morningReminderMinute),
              enabled: s.notificationsEnabled && s.morningReminderEnabled,
              onTap: () => onPickTime(_ReminderType.morning),
              t: t,
            ),
            const SizedBox(width: 10),
            _ReminderChip(
              icon: Icons.alarm_outlined,
              label: 'Work end',
              time: _fmt(s.workEndHour, s.workEndMinute),
              enabled: s.notificationsEnabled && s.workEndNotificationEnabled,
              onTap: () => onPickTime(_ReminderType.workEnd),
              t: t,
            ),
          ],
        );
      },
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool enabled;
  final VoidCallback onTap;
  final NTheme t;

  const _ReminderChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadii.large),
            boxShadow: t.boxShadow,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: enabled ? t.accent : t.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(fontSize: 10, color: t.textTertiary, fontWeight: FontWeight.w600)),
                    Text(time,
                        style: TextStyle(fontSize: 13, color: enabled ? t.textPrimary : t.textTertiary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 13, color: t.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
