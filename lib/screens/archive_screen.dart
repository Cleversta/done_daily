import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../bloc/daily_state.dart';
import '../models/daily_model.dart';
import '../theme/app_theme.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late DateTime _viewMonth;

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
    if (_viewMonth.year == now.year && _viewMonth.month == now.month) return;
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final now = DateTime.now();
    final isCurrentMonth = _viewMonth.year == now.year && _viewMonth.month == now.month;

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
                    child: Text('Archive', style: Theme.of(context).textTheme.displayLarge),
                  ),
                  _NavArrow(icon: Icons.chevron_left, onTap: _prevMonth),
                  const SizedBox(width: 4),
                  _NavArrow(
                    icon: Icons.chevron_right,
                    onTap: isCurrentMonth ? null : _nextMonth,
                  ),
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
                builder: (context, state) {
                  if (state is MonthlyArchiveLoaded) {
                    return _MonthBody(state: state, viewMonth: _viewMonth);
                  }
                  return Center(
                    child: CircularProgressIndicator(color: t.textPrimary),
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

  const _MonthBody({required this.state, required this.viewMonth});

  @override
  Widget build(BuildContext context) {
    final dataMap = {for (final d in state.monthlyData) d.id: d};

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'COMPLETED',
                value: '${state.completedDays}',
                sub: 'days',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'TRACKED',
                value: '${state.totalTrackedDays}',
                sub: 'days',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'STREAK',
                value: '${state.streak}',
                sub: 'days 🔥',
              ),
            ),
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
    final t = NTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (innerCtx) => BlocProvider.value(
        value: context.read<DailyBloc>(),
        child: _DayDetailSheet(date: date, daily: daily),
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
                onTap: isFuture ? null : () => _showDaySheet(context, date, daily),
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

  const _DayDetailSheet({required this.date, required this.daily});

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  late TextEditingController _reflectionController;

  @override
  void initState() {
    super.initState();
    _reflectionController = TextEditingController(text: widget.daily?.reflection ?? '');
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final now = DateTime.now();
    final date = widget.date;
    final daily = widget.daily;
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

          if (daily == null) ...[
            Text('No data recorded for this day.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textTertiary)),
          ] else if (daily.isRestDay) ...[
            Row(
              children: [
                const Icon(Icons.self_improvement_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Rest day', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent)),
              ],
            ),
          ] else if (daily.goals.isEmpty) ...[
            Text('No goals set for this day.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textTertiary)),
          ] else ...[
            // Summary line
            Text(
              '${daily.completedGoalsCount} of ${daily.totalGoalsCount} completed',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: daily.allGoalsCompleted ? AppColors.success : t.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Goal list
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

          // Reflection section — editable for non-rest days with data
          if (daily != null && !daily.isRestDay) ...[
            Divider(height: 24, color: t.shadowDark),
            Text(
              'Reflection',
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
      ),
    );
  }
}
