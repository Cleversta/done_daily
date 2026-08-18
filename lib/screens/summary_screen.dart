import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../bloc/daily_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';
import '../models/daily_model.dart';
import '../models/settings_model.dart';
import '../theme/app_theme.dart';
import '../services/support_card_service.dart';
import '../widgets/support_bottom_sheet.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _supportChecked = false;

  void _maybeShowSupport(int streak) {
    if (_supportChecked) return;
    _supportChecked = true;
    if (streak >= 5 && SupportCardService.shouldShow(SupportCardService.triggerWeekly)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSupportSheet(context, SupportCardService.triggerWeekly);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: BlocBuilder<DailyBloc, DailyState>(
          builder: (context, dailyState) {
            if (dailyState is DailyLoaded) _maybeShowSupport(dailyState.streak);
            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                final settings = settingsState is SettingsLoaded
                    ? settingsState.settings
                    : const AppSettings();
                final daily = dailyState is DailyLoaded ? dailyState.daily : null;
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final isTomorrowRestDay = settings.restDays.contains(tomorrow.weekday);
                final tomorrowGoals = context
                    .read<DailyBloc>()
                    .recurringGoals
                    .where((g) => g.appliesOn(tomorrow.weekday))
                    .toList();
                final carryover = daily != null && !daily.isRestDay
                    ? daily.goals.where((g) => !g.isCompleted && g.recurringTemplateId == null).toList()
                    : [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    // Header
                    Text('Recap', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 28),

                    // ── Today Summary ──────────────────────────────────
                    _SectionLabel('TODAY'),
                    const SizedBox(height: 10),

                    if (daily == null || daily.isRestDay)
                      _RestDayCard(t: t)
                    else
                      _TodaySummaryCard(daily: daily, t: t),

                    // ── Focus time ─────────────────────────────────────
                    if (daily != null && daily.focusMinutes > 0) ...[
                      const SizedBox(height: 24),
                      _SectionLabel('FOCUS TIME'),
                      const SizedBox(height: 10),
                      _FocusTimeCard(minutes: daily.focusMinutes, t: t),
                    ],

                    // ── Carryover ──────────────────────────────────────
                    if (carryover.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionLabel('CARRYING OVER'),
                      const SizedBox(height: 10),
                      _CarryoverCard(goals: carryover, t: t),
                    ],

                    const SizedBox(height: 24),

                    // ── Note for tomorrow ──────────────────────────────
                    _SectionLabel('NOTE FOR TOMORROW'),
                    const SizedBox(height: 10),
                    _TomorrowNoteCard(
                      saved: daily?.tomorrowNote ?? '',
                      t: t,
                      settings: settings,
                      daily: daily,
                      onSave: (text) => context.read<DailyBloc>().add(UpdateTomorrowNoteEvent(text)),
                      onUseNote: (date, title) => context.read<DailyBloc>().add(AddGoalForDateEvent(date: date, title: title)),
                    ),

                    const SizedBox(height: 24),

                    // ── Tomorrow Preview (only if something to show) ───
                    if (isTomorrowRestDay || tomorrowGoals.isNotEmpty) ...[
                      _SectionLabel('TOMORROW — ${DateFormat('EEE, MMM d').format(tomorrow).toUpperCase()}'),
                      const SizedBox(height: 10),
                      _TomorrowCard(
                        isRestDay: isTomorrowRestDay,
                        tomorrowGoals: tomorrowGoals,
                        t: t,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── Today summary card ───────────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final Daily daily;
  final NTheme t;
  const _TodaySummaryCard({required this.daily, required this.t});

  @override
  Widget build(BuildContext context) {
    final total = daily.totalGoalsCount;
    final done = daily.completedGoalsCount;
    final allDone = daily.allGoalsCompleted && total > 0;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total == 0
                            ? 'No goals today'
                            : allDone
                                ? 'All done!'
                                : '$done of $total completed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: allDone ? AppColors.success : t.textPrimary,
                        ),
                      ),
                      if (total > 0)
                        Text(
                          allDone ? 'Great work today' : '${total - done} remaining',
                          style: TextStyle(fontSize: 12, color: t.textTertiary),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: allDone
                        ? AppColors.success.withValues(alpha: 0.12)
                        : t.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      allDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 26,
                      color: allDone ? AppColors.success : t.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          if (total > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  minHeight: 5,
                  backgroundColor: t.shadowDark.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(
                    allDone ? AppColors.success : t.accent,
                  ),
                ),
              ),
            ),
          ],

          // Divider
          if (daily.goals.isNotEmpty) Divider(height: 1, color: t.shadowDark),

          // Goal list
          ...daily.goals.map((g) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      g.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: g.isCompleted ? AppColors.success : t.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        g.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: g.isCompleted ? t.textTertiary : t.textPrimary,
                          decoration: g.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: t.textTertiary,
                        ),
                      ),
                    ),
                    if (g.isPriority)
                      Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                  ],
                ),
              )),

          if (daily.goals.isNotEmpty) const SizedBox(height: 12),

          // Reflection
          if (daily.reflection.isNotEmpty) ...[
            Divider(height: 1, color: t.shadowDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_rounded, size: 16, color: t.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      daily.reflection,
                      style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Rest day card ────────────────────────────────────────────────────────────

class _RestDayCard extends StatelessWidget {
  final NTheme t;
  const _RestDayCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.self_improvement_outlined, size: 22, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(
            'Rest day — enjoy your time off',
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Tomorrow card ────────────────────────────────────────────────────────────

class _TomorrowCard extends StatelessWidget {
  final bool isRestDay;
  final List tomorrowGoals;
  final NTheme t;
  const _TomorrowCard({required this.isRestDay, required this.tomorrowGoals, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRestDay)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.self_improvement_outlined, size: 20, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Text(
                    'Rest day tomorrow',
                    style: TextStyle(fontSize: 14, color: t.textSecondary),
                  ),
                ],
              ),
            )
          else if (tomorrowGoals.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined, size: 20, color: t.textTertiary),
                  const SizedBox(width: 12),
                  Text(
                    'No recurring goals scheduled',
                    style: TextStyle(fontSize: 14, color: t.textTertiary),
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                '${tomorrowGoals.length} recurring goal${tomorrowGoals.length > 1 ? 's' : ''} scheduled',
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            ),
            ...tomorrowGoals.asMap().entries.map((entry) {
              final g = entry.value;
              final isLast = entry.key == tomorrowGoals.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, size: 14, color: t.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.title,
                            style: TextStyle(fontSize: 13, color: t.textPrimary),
                          ),
                        ),
                        if (g.isPriority)
                          Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: t.shadowDark.withValues(alpha: 0.5)),
                ],
              );
            }),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─── Focus time card ──────────────────────────────────────────────────────────

class _FocusTimeCard extends StatelessWidget {
  final int minutes;
  final NTheme t;
  const _FocusTimeCard({required this.minutes, required this.t});

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final label = hours > 0 ? '${hours}h ${mins}min' : '${mins}min';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(Icons.timer_outlined, size: 20, color: t.accent)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.textPrimary)),
              Text('focused today', style: TextStyle(fontSize: 12, color: t.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Carryover card ───────────────────────────────────────────────────────────

class _CarryoverCard extends StatelessWidget {
  final List goals;
  final NTheme t;
  const _CarryoverCard({required this.goals, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'These will be suggested tomorrow',
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ),
          ...goals.asMap().entries.map((entry) {
            final g = entry.value;
            final isLast = entry.key == goals.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 14, color: t.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(g.title, style: TextStyle(fontSize: 13, color: t.textSecondary)),
                      ),
                      if (g.isPriority)
                        Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: t.shadowDark.withValues(alpha: 0.5)),
              ],
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─── Tomorrow note card ───────────────────────────────────────────────────────

class _TomorrowNoteCard extends StatefulWidget {
  final String saved;
  final NTheme t;
  final AppSettings settings;
  final Daily? daily;
  final void Function(String) onSave;
  final void Function(DateTime date, String title) onUseNote;
  const _TomorrowNoteCard({
    required this.saved,
    required this.t,
    required this.settings,
    required this.daily,
    required this.onSave,
    required this.onUseNote,
  });

  @override
  State<_TomorrowNoteCard> createState() => _TomorrowNoteCardState();
}

class _TomorrowNoteCardState extends State<_TomorrowNoteCard> {
  final _controller = TextEditingController();
  late List<String> _notes;

  @override
  void initState() {
    super.initState();
    _notes = _parse(widget.saved);
  }

  @override
  void didUpdateWidget(_TomorrowNoteCard old) {
    super.didUpdateWidget(old);
    if (old.saved != widget.saved) {
      _notes = _parse(widget.saved);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parse(String raw) =>
      raw.split('\n').where((s) => s.trim().isNotEmpty).toList();

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _notes.add(text));
    _controller.clear();
    widget.onSave(_notes.join('\n'));
  }

  void _delete(int index) {
    setState(() => _notes.removeAt(index));
    widget.onSave(_notes.join('\n'));
  }

  (DateTime, String) _resolveTarget() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = widget.settings;
    final d = widget.daily;

    final endHour = d?.workEndHour ?? s.workEndHour;
    final endMin = d?.workEndMinute ?? s.workEndMinute;
    var workEnd = DateTime(today.year, today.month, today.day, endHour, endMin);
    if (now.difference(workEnd).inHours > 12) workEnd = workEnd.add(const Duration(days: 1));

    final todayRestDay = d?.isRestDay ?? s.restDays.contains(today.weekday);
    final stillWorking = !todayRestDay && now.isBefore(workEnd);
    if (stillWorking) return (today, 'Use today');

    var target = today.add(const Duration(days: 1));
    for (int i = 0; i < 6; i++) {
      if (!s.restDays.contains(target.weekday)) break;
      target = target.add(const Duration(days: 1));
    }
    if (target.difference(today).inDays == 1) return (target, 'Use tomorrow');
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (target, 'Use ${wd[target.weekday - 1]}');
  }

  void _useNote(int index) {
    final note = _notes[index];
    final (date, _) = _resolveTarget();
    widget.onUseNote(date, note);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saved notes list
          ..._notes.asMap().entries.map((entry) {
            final i = entry.key;
            final note = entry.value;
            final (_, label) = _resolveTarget();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wb_twilight_rounded, size: 15, color: t.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(fontSize: 13, color: t.textPrimary, height: 1.4),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _delete(i),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, size: 16, color: t.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(39, 0, 14, 10),
                  child: GestureDetector(
                    onTap: () => _useNote(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_task_rounded, size: 12, color: t.accent),
                          const SizedBox(width: 4),
                          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.accent)),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: t.shadowDark.withValues(alpha: 0.5)),
              ],
            );
          }),

          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 16, color: t.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 13, color: t.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a note for tomorrow...',
                      hintStyle: TextStyle(fontSize: 13, color: t.textTertiary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                GestureDetector(
                  onTap: _add,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: t.textTertiary),
    );
  }
}
