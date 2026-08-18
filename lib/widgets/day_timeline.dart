import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../models/custom_reminder.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'break_sheet.dart';

/// Visual map of the working day: start → breaks → wrap-up → end.
class DayTimeline extends StatelessWidget {
  final DateTime now;
  const DayTimeline({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final s = state is SettingsLoaded ? state.settings : const AppSettings();
        final t = NTheme.of(context);
        final breaks = [...s.customReminders]
          ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

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
        final wrapMins = end - s.wrapUpMinutesBefore;

        // Phase + remaining for the subtitle under the header
        final startDt = DateTime(now.year, now.month, now.day, s.workStartHour, s.workStartMinute);
        var endDt = DateTime(now.year, now.month, now.day, s.workEndHour, s.workEndMinute);
        if (!endDt.isAfter(startDt)) endDt = endDt.add(const Duration(days: 1));
        String phaseLine;
        if (now.isBefore(startDt)) {
          final d = startDt.difference(now);
          phaseLine = d.inHours > 0
              ? 'Before work · starts in ${d.inHours}h ${d.inMinutes % 60}m'
              : 'Before work · starts in ${d.inMinutes}m';
        } else if (now.isAfter(endDt)) {
          phaseLine = 'After hours · day is closed';
        } else {
          final d = endDt.difference(now);
          phaseLine = d.inHours > 0
              ? 'In work · ends in ${d.inHours}h ${d.inMinutes % 60}m'
              : 'In work · ends in ${d.inMinutes}m';
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadii.large),
            boxShadow: t.boxShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'YOUR DAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: t.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _editWorkWindow(context, s),
                    child: Text(
                      s.workWindowDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                phaseLine,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary),
              ),
              const SizedBox(height: 12),

              // Track
              SizedBox(
                height: 28,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Base track
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 12,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: t.textTertiary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Progress filled
                        Positioned(
                          left: 0,
                          top: 12,
                          child: Container(
                            width: (w * nowPos).clamp(0.0, w),
                            height: 4,
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Start marker
                        _marker(w, 0, t.accent, Icons.play_arrow_rounded),
                        // Break markers
                        for (final b in breaks)
                          if (b.enabled)
                            _marker(
                              w,
                              pos(b.minutesOfDay),
                              t.warning,
                              Icons.free_breakfast_rounded,
                            ),
                        // Wrap-up marker
                        if (s.wrapUpEnabled && s.workEndNotificationEnabled)
                          _marker(w, pos(wrapMins), t.textSecondary, Icons.hourglass_bottom_rounded),
                        // End marker
                        _marker(w, 1.0, t.success, Icons.flag_rounded),
                        // Now needle
                        Positioned(
                          left: (w * nowPos).clamp(0.0, w) - 1,
                          top: 4,
                          child: Container(
                            width: 2,
                            height: 20,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Legend chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Legend(
                    icon: Icons.play_arrow_rounded,
                    label: 'Start ${s.workStartDisplay}',
                    color: t.accent,
                    onTap: () => _pickWorkStart(context, s),
                    t: t,
                  ),
                  for (final b in breaks.take(3))
                    _Legend(
                      icon: Icons.free_breakfast_rounded,
                      label: b.label,
                      color: b.enabled ? t.warning : t.textTertiary,
                      onTap: () => BreakSheet.show(context, existing: b),
                      t: t,
                    ),
                  if (breaks.length > 3)
                    _Legend(
                      icon: Icons.more_horiz,
                      label: '+${breaks.length - 3}',
                      color: t.textTertiary,
                      onTap: () => BreakSheet.show(context),
                      t: t,
                    ),
                  _Legend(
                    icon: Icons.flag_rounded,
                    label: 'End ${s.workEndDisplay}',
                    color: t.success,
                    onTap: () => _pickWorkEnd(context, s),
                    t: t,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _marker(double trackW, double p, Color color, IconData icon) {
    return Positioned(
      left: (trackW * p).clamp(0.0, trackW) - 8,
      top: 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 10, color: Colors.white),
      ),
    );
  }

  Future<void> _editWorkWindow(BuildContext context, AppSettings s) async {
    // Open start picker first as a simple entry; end stays on long-press of end legend
    await _pickWorkStart(context, s);
  }

  Future<void> _pickWorkStart(BuildContext context, AppSettings s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.workStartHour, minute: s.workStartMinute),
    );
    if (picked == null || !context.mounted) return;
    final updated = s.copyWith(workStartHour: picked.hour, workStartMinute: picked.minute);
    context.read<SettingsBloc>().add(UpdateSettingsEvent(updated));
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
      await NotificationService.instance.syncNotifications(
        enabled: true,
        workEndEnabled: updated.workEndNotificationEnabled,
        workEndHour: updated.workEndHour,
        workEndMinute: updated.workEndMinute,
        morningEnabled: updated.morningReminderEnabled,
        morningHour: updated.morningReminderHour,
        morningMinute: updated.morningReminderMinute,
        weeklyEnabled: updated.weeklyReminderEnabled,
        weeklyHour: updated.weeklyReminderHour,
        weeklyMinute: updated.weeklyReminderMinute,
        customReminders: updated.customReminders,
        wrapUpEnabled: updated.wrapUpEnabled,
        wrapUpMinutesBefore: updated.wrapUpMinutesBefore,
      );
    }
  }
}

class _Legend extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final NTheme t;

  const _Legend({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
