import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../bloc/daily_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../models/daily_model.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late DateTime _viewMonth;

  static const _weekdays = {
    1: 'Mon', 2: 'Tue', 3: 'Wed',
    4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime.now();
    _load();
  }

  void _load() {
    context.read<DailyBloc>().add(
      LoadMonthlyArchiveEvent(year: _viewMonth.year, month: _viewMonth.month),
    );
  }

  void _prevMonth() {
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final maxMonth = DateTime(now.year, now.month + 12);
    if (_viewMonth.isAfter(maxMonth)) return;
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));
    _load();
  }

  Future<void> _pickWorkEndTime(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.workEndHour, minute: settings.workEndMinute),
    );
    if (picked == null || !mounted) return;
    final updated = settings.copyWith(workEndHour: picked.hour, workEndMinute: picked.minute);
    context.read<SettingsBloc>().add(UpdateSettingsEvent(updated));
    context.read<DailyBloc>().add(SetWorkEndTimeEvent(hour: picked.hour, minute: picked.minute));
    if (settings.notificationsEnabled && settings.workEndNotificationEnabled) {
      await NotificationService.instance.scheduleWorkEndNotification(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Calendar', style: Theme.of(context).textTheme.displayLarge),
                  ),
                  _NavArrow(icon: Icons.chevron_left, onTap: _prevMonth),
                  const SizedBox(width: 4),
                  _NavArrow(icon: Icons.chevron_right, onTap: _nextMonth),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text(
                DateFormat('MMMM yyyy').format(_viewMonth),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 20),

            // Body
            Expanded(
              child: BlocBuilder<DailyBloc, DailyState>(
                builder: (context, dailyState) {
                  return BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, settingsState) {
                      final settings = settingsState is SettingsLoaded ? settingsState.settings : const AppSettings();
                      if (dailyState is MonthlyArchiveLoaded) {
                        return _MonthBody(
                          state: dailyState,
                          viewMonth: _viewMonth,
                          settings: settings,
                          onPickWorkEnd: () => _pickWorkEndTime(settings),
                          onToggleRestDay: (day) {
                            final days = List<int>.from(settings.restDays);
                            days.contains(day) ? days.remove(day) : days.add(day);
                            context.read<SettingsBloc>().add(UpdateSettingsEvent(settings.copyWith(restDays: days)));
                          },
                          weekdays: _weekdays,
                        );
                      }
                      return Center(child: CircularProgressIndicator(color: t.textPrimary));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month body ───────────────────────────────────────────────────────────────

class _MonthBody extends StatelessWidget {
  final MonthlyArchiveLoaded state;
  final DateTime viewMonth;
  final AppSettings settings;
  final VoidCallback onPickWorkEnd;
  final void Function(int day) onToggleRestDay;
  final Map<int, String> weekdays;

  const _MonthBody({
    required this.state,
    required this.viewMonth,
    required this.settings,
    required this.onPickWorkEnd,
    required this.onToggleRestDay,
    required this.weekdays,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final dataMap = {for (final d in state.monthlyData) d.id: d};

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        // ── Work Schedule ─────────────────────────────────────────────
        _SectionLabel('WORK SCHEDULE'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadii.large),
            boxShadow: t.boxShadow,
          ),
          child: Column(
            children: [
              // Work end time
              GestureDetector(
                onTap: onPickWorkEnd,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 20, color: t.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Work ends at', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Text(settings.workEndDisplay, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.accent)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: t.textTertiary),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: t.shadowDark),
              // Rest days
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.weekend_outlined, size: 20, color: t.textSecondary),
                        const SizedBox(width: 12),
                        Text('Weekly rest days', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: weekdays.entries.map((e) {
                        final isSelected = settings.restDays.contains(e.key);
                        return GestureDetector(
                          onTap: () => onToggleRestDay(e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              boxShadow: isSelected ? t.insetShadow : t.buttonShadow,
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.success : t.textTertiary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Stats row ─────────────────────────────────────────────────
        _SectionLabel('THIS MONTH'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'COMPLETED', value: '${state.completedDays}', sub: 'days')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'TRACKED', value: '${state.totalTrackedDays}', sub: 'days')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'STREAK', value: '${state.streak}', sub: 'days 🔥')),
          ],
        ),
        const SizedBox(height: 20),

        // Calendar grid
        _CalendarGrid(viewMonth: viewMonth, dataMap: dataMap),
        const SizedBox(height: 20),

        // Daily breakdown
        ...state.monthlyData.reversed.map((daily) => _DayRow(daily: daily)),
      ],
    );
  }
}

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

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatCard({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(sub, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

// ─── Calendar grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatefulWidget {
  final DateTime viewMonth;
  final Map<String, Daily> dataMap;

  const _CalendarGrid({required this.viewMonth, required this.dataMap});

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  DateTime? _selectedDate;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showDaySheet(BuildContext context, DateTime date, Daily? daily) {
    setState(() => _selectedDate = date);
    final now = DateTime.now();
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
    final t = NTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (innerCtx) => BlocProvider.value(
        value: context.read<DailyBloc>(),
        child: _DayDetailSheet(date: date, daily: daily, isFuture: isFuture),
      ),
    ).whenComplete(() => setState(() => _selectedDate = null));
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final viewMonth = widget.viewMonth;
    final dataMap = widget.dataMap;
    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: _days
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: Theme.of(context).textTheme.labelMedium),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Day cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox();
              final day = index - startOffset + 1;
              final date = DateTime(viewMonth.year, viewMonth.month, day);
              final isFuture = date.isAfter(now);
              final daily = dataMap[_key(date)];
              final isToday = date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;

              Color dotColor = t.textTertiary.withValues(alpha: 0.2);
              if (!isFuture && daily != null) {
                if (daily.isRestDay) {
                  dotColor = AppColors.accent.withValues(alpha: 0.3);
                } else if (daily.allGoalsCompleted && daily.totalGoalsCount > 0) {
                  dotColor = AppColors.success.withValues(alpha: 0.7);
                } else if (daily.completedGoalsCount > 0) {
                  dotColor = AppColors.success.withValues(alpha: 0.3);
                }
              }

              return GestureDetector(
                onTap: () => _showDaySheet(context, date, daily),
                child: Container(
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: _selectedDate != null &&
                            _selectedDate!.day == date.day &&
                            _selectedDate!.month == date.month &&
                            _selectedDate!.year == date.year
                        ? Border.all(color: Colors.white, width: 2)
                        : isToday
                            ? Border.all(color: t.textPrimary, width: 1.5)
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isFuture ? t.textTertiary.withValues(alpha: 0.4) : t.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.success, label: 'All done'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.success.withValues(alpha: 0.3), label: 'Partial'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.accent.withValues(alpha: 0.3), label: 'Rest'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

// ─── Day row ──────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final Daily daily;
  const _DayRow({required this.daily});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final now = DateTime.now();
    final isToday = daily.date.year == now.year &&
        daily.date.month == now.month &&
        daily.date.day == now.day;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppRadii.large),
          boxShadow: t.boxShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('EEE, MMM d').format(daily.date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.textPrimary,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 10,
                            color: t.background,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                _dayStatus(context, daily),
              ],
            ),
            if (!daily.isRestDay && daily.goals.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...daily.goals.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(
                          g.isCompleted ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: g.isCompleted ? AppColors.success : t.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            g.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: g.isCompleted ? t.textSecondary : t.textTertiary,
                              decoration: g.isCompleted ? TextDecoration.lineThrough : null,
                              decorationColor: t.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dayStatus(BuildContext context, Daily daily) {
    final t = NTheme.of(context);
    if (daily.isRestDay) {
      return Text('Rest', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.accent));
    }
    if (daily.totalGoalsCount == 0) {
      return Text('No goals', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: t.textTertiary));
    }
    final color = daily.allGoalsCompleted ? AppColors.success : t.textSecondary;
    return Text(
      '${daily.completedGoalsCount}/${daily.totalGoalsCount}',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
    );
  }
}

// ─── Nav arrow ────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: t.surface,
          shape: BoxShape.circle,
          boxShadow: onTap != null ? t.buttonShadow : t.insetShadow,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? t.textPrimary : t.textTertiary,
        ),
      ),
    );
  }
}

// ─── Day detail bottom sheet ──────────────────────────────────────────────────

class _DayDetailSheet extends StatefulWidget {
  final DateTime date;
  final Daily? daily;
  final bool isFuture;

  const _DayDetailSheet({required this.date, required this.daily, this.isFuture = false});

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  late TextEditingController _reflectionController;
  late bool _isRestDay;

  @override
  void initState() {
    super.initState();
    _reflectionController = TextEditingController(text: widget.daily?.reflection ?? '');
    _isRestDay = widget.daily?.isRestDay ?? false;
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  void _toggleRestDay() {
    final newValue = !_isRestDay;
    setState(() => _isRestDay = newValue);
    context.read<DailyBloc>().add(
      ToggleArchiveRestDayEvent(date: widget.date, isRestDay: newValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final now = DateTime.now();
    final date = widget.date;
    final daily = widget.daily;
    final isFuture = widget.isFuture;
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: t.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Date header
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.textPrimary,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(fontSize: 11, color: t.background, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Rest day toggle — always visible for past days
          GestureDetector(
            onTap: _toggleRestDay,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.self_improvement_outlined,
                  size: 18,
                  color: _isRestDay ? AppColors.accent : t.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rest day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isRestDay ? AppColors.accent : t.textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: _isRestDay,
                  onChanged: (_) => _toggleRestDay(),
                  activeThumbColor: AppColors.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          if (!_isRestDay && !isFuture) ...[
            const SizedBox(height: 12),
            if (daily == null || daily.goals.isEmpty)
              Text(
                'No goals set for this day.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textTertiary),
              )
            else ...[
              Text(
                '${daily.completedGoalsCount} of ${daily.totalGoalsCount} completed',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: daily.allGoalsCompleted ? AppColors.success : t.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...daily.goals.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      g.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: g.isCompleted ? AppColors.success : t.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        g.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: g.isCompleted ? t.textPrimary : t.textSecondary,
                          decoration: g.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: t.textTertiary,
                        ),
                      ),
                    ),
                    if (g.isPriority)
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                  ],
                ),
              )),
            ],

            // Reflection — only for non-rest days with a daily record
            if (daily != null) ...[
              Divider(height: 24, color: t.shadowDark),
              Text('Reflection', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _reflectionController,
                maxLines: null,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 13, color: t.textPrimary),
                decoration: InputDecoration(
                  hintText: 'How did today go?',
                  filled: true,
                  fillColor: t.surface,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(color: t.textTertiary, fontSize: 13),
                ),
                onChanged: (value) {
                  context.read<DailyBloc>().add(
                    UpdateArchiveReflectionEvent(dailyId: daily.id, text: value),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
