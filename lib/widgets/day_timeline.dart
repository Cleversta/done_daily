import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'break_sheet.dart';

/// Hero card for the work day — status, countdown, progress, start/end.
class DayTimeline extends StatelessWidget {
  final DateTime now;
  const DayTimeline({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final s = state is SettingsLoaded ? state.settings : const AppSettings();
        final t = NTheme.of(context);

        final nowMins = now.hour * 60 + now.minute;
        final start = s.workStartMinutes;
        final end = s.workEndMinutes;
        final span = (end > start) ? (end - start) : (24 * 60 - start + end);
        final safeSpan = span <= 0 ? 1 : span;

        double pos(int mins) {
          var rel = mins - start;
          if (end <= start && mins < start) rel += 24 * 60;
          if (rel < 0) rel = 0;
          if (rel > safeSpan) rel = safeSpan;
          return rel / safeSpan;
        }

        final nowPos = pos(nowMins).clamp(0.0, 1.0);

        final startDt = DateTime(now.year, now.month, now.day, s.workStartHour, s.workStartMinute);
        var endDt = DateTime(now.year, now.month, now.day, s.workEndHour, s.workEndMinute);
        if (!endDt.isAfter(startDt)) endDt = endDt.add(const Duration(days: 1));

        late final String statusTitle;
        late final String statusSub;
        late final Color statusColor;
        late final IconData statusIcon;
        if (now.isBefore(startDt)) {
          final d = startDt.difference(now);
          statusTitle = 'Before work';
          statusSub = d.inHours > 0
              ? 'Starts in ${d.inHours}h ${d.inMinutes % 60}m'
              : 'Starts in ${d.inMinutes}m';
          statusColor = t.accent;
          statusIcon = Icons.wb_twilight_rounded;
        } else if (now.isAfter(endDt)) {
          statusTitle = 'Day closed';
          statusSub = 'Nice work — rest now';
          statusColor = t.success;
          statusIcon = Icons.check_circle_rounded;
        } else {
          final d = endDt.difference(now);
          statusTitle = 'Working';
          statusSub = d.inHours > 0
              ? '${d.inHours}h ${d.inMinutes % 60}m until end'
              : '${d.inMinutes}m until end';
          statusColor = t.accent;
          statusIcon = Icons.bolt_rounded;
        }

        final enabledBreaks = s.customReminders.where((b) => b.enabled).toList()
          ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
        final pct = (nowPos * 100).round().clamp(0, 100);

        String? nextBreakLine;
        for (final b in enabledBreaks) {
          if (b.minutesOfDay > nowMins) {
            final minsLeft = b.minutesOfDay - nowMins;
            if (minsLeft >= 60) {
              final h = minsLeft ~/ 60;
              final m = minsLeft % 60;
              nextBreakLine = m > 0 ? '${b.label} in ${h}h ${m}m' : '${b.label} in ${h}h';
            } else {
              nextBreakLine = '${b.label} in ${minsLeft}m';
            }
            break;
          }
        }

        final hour = now.hour;
        final Color phaseWash;
        if (hour < 11) {
          phaseWash = const Color(0xFFA5B4FC).withValues(alpha: 0.10);
        } else if (hour < 16) {
          phaseWash = const Color(0xFFFDE68A).withValues(alpha: 0.12);
        } else if (hour < 19) {
          phaseWash = const Color(0xFFFDBA74).withValues(alpha: 0.10);
        } else {
          phaseWash = const Color(0xFFC4B5FD).withValues(alpha: 0.10);
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(t.surface, phaseWash, 1.0)!, t.surface],
            ),
            borderRadius: BorderRadius.circular(AppRadii.extraLarge),
            boxShadow: t.boxShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: status badge + schedule range
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$pct% of day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textTertiary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Big countdown / status
              Text(
                statusSub,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: t.textPrimary,
                  height: 1.15,
                ),
              ),
              if (nextBreakLine != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.free_breakfast_rounded, size: 14, color: t.warning),
                    const SizedBox(width: 6),
                    Text(
                      nextBreakLine!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Progress track with soft fill
              SizedBox(
                height: 10,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: w,
                          height: 10,
                          decoration: BoxDecoration(
                            color: t.textTertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          width: (w * nowPos).clamp(0.0, w),
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.7),
                                statusColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        ),
                        // "now" knob
                        Positioned(
                          left: ((w * nowPos) - 7).clamp(0.0, w - 14),
                          top: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: t.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: statusColor, width: 3),
                              boxShadow: t.subtleShadow,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Start / End time pills
              Row(
                children: [
                  Expanded(
                    child: _TimePill(
                      label: 'START',
                      time: s.workStartDisplay,
                      icon: Icons.play_arrow_rounded,
                      color: t.accent,
                      onTap: () => _pickWorkStart(context, s),
                      t: t,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimePill(
                      label: 'END',
                      time: s.workEndDisplay,
                      icon: Icons.flag_rounded,
                      color: t.success,
                      onTap: () => _pickWorkEnd(context, s),
                      t: t,
                    ),
                  ),
                ],
              ),

              // Breaks strip (compact)
              if (enabledBreaks.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: enabledBreaks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final b = enabledBreaks[i];
                      return GestureDetector(
                        onTap: () => BreakSheet.show(context, existing: b),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.free_breakfast_rounded, size: 13, color: t.warning),
                              const SizedBox(width: 5),
                              Text(
                                '${b.label} ${b.timeDisplay}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => BreakSheet.show(context),
                  child: Text(
                    '+ Add lunch or a break',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickWorkStart(BuildContext context, AppSettings s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.workStartHour, minute: s.workStartMinute),
    );
    if (picked == null || !context.mounted) return;
    final updated = s.copyWith(workStartHour: picked.hour, workStartMinute: picked.minute);
    context.read<SettingsBloc>().add(UpdateSettingsEvent(updated));
    if (s.notificationsEnabled) {
      await NotificationService.instance.syncFromSettings(updated);
    }
  }

  Future<void> _pickWorkEnd(BuildContext context, AppSettings s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.workEndHour, minute: s.workEndMinute),
    );
    if (picked == null || !context.mounted) return;
    final updated = s.copyWith(workEndHour: picked.hour, workEndMinute: picked.minute);
    context.read<SettingsBloc>().add(UpdateSettingsEvent(updated));
    context.read<DailyBloc>().add(SetWorkEndTimeEvent(hour: picked.hour, minute: picked.minute));
    if (s.notificationsEnabled) {
      await NotificationService.instance.syncFromSettings(updated);
    }
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final NTheme t;

  const _TimePill({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(AppRadii.large),
          boxShadow: t.insetShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: t.textTertiary,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 13, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}