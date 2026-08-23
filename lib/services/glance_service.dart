import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/daily_model.dart';
import '../models/settings_model.dart';

/// At-a-glance payload for the Android home-screen widget.
///
/// Android provider class: `com.cleversta.done_daily.DoneDailyWidgetProvider`
/// Call [GlanceService.update] whenever daily goals or settings change.
///
/// Important: remaining-time strings are also recomputed natively in the
/// widget provider so the countdown keeps ticking even when the app is closed.
class GlanceSnapshot {
  final int goalsLeft;
  final int goalsTotal;
  final String workEndLabel;
  final String? nextBreakLabel;
  final String remainingLabel;
  final bool isRestDay;
  final String phaseLabel;

  /// Raw schedule values so the native widget can recompute time remaining.
  final int workStartHour;
  final int workStartMinute;
  final int workEndHour;
  final int workEndMinute;

  const GlanceSnapshot({
    required this.goalsLeft,
    required this.goalsTotal,
    required this.workEndLabel,
    required this.nextBreakLabel,
    required this.remainingLabel,
    required this.isRestDay,
    required this.phaseLabel,
    required this.workStartHour,
    required this.workStartMinute,
    required this.workEndHour,
    required this.workEndMinute,
  });

  /// e.g. "2 goals left · ends in 1h 20m · Lunch 12:00"
  String get summaryLine {
    if (isRestDay) return 'Rest day — take it easy';
    final parts = <String>[];
    if (goalsTotal > 0) {
      parts.add(goalsLeft == 0
          ? 'All goals done'
          : '$goalsLeft goal${goalsLeft == 1 ? '' : 's'} left');
    } else {
      parts.add('No goals yet');
    }
    if (remainingLabel.isNotEmpty) parts.add(remainingLabel);
    if (nextBreakLabel != null) parts.add(nextBreakLabel!);
    return parts.join(' · ');
  }

  Map<String, String> toWidgetData() => {
        'goalsLeft': '$goalsLeft',
        'goalsTotal': '$goalsTotal',
        'workEndLabel': workEndLabel,
        'nextBreakLabel': nextBreakLabel ?? '',
        'remainingLabel': remainingLabel,
        'isRestDay': isRestDay ? '1' : '0',
        'phaseLabel': phaseLabel,
        'summaryLine': summaryLine,
        'title': isRestDay
            ? 'Rest day'
            : (goalsTotal == 0
                ? 'Plan your day'
                : (goalsLeft == 0 ? 'All done' : '$goalsLeft left')),
        // Raw numbers for native recompute of countdown
        'workStartHour': '$workStartHour',
        'workStartMinute': '$workStartMinute',
        'workEndHour': '$workEndHour',
        'workEndMinute': '$workEndMinute',
      };

  static GlanceSnapshot from({
    required Daily? daily,
    required AppSettings settings,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final isRest = daily?.isRestDay ?? settings.restDays.contains(n.weekday);
    final total = daily?.totalGoalsCount ?? 0;
    final done = daily?.completedGoalsCount ?? 0;
    final left = (total - done).clamp(0, total);

    final start = DateTime(
        n.year, n.month, n.day, settings.workStartHour, settings.workStartMinute);
    var workEnd = DateTime(
        n.year, n.month, n.day, settings.workEndHour, settings.workEndMinute);
    if (workEnd.isBefore(start) || workEnd.isAtSameMomentAs(start)) {
      workEnd = workEnd.add(const Duration(days: 1));
    }

    String remainingLabel;
    String phaseLabel;
    if (isRest) {
      remainingLabel = '';
      phaseLabel = 'Rest day';
    } else if (n.isBefore(start)) {
      final until = start.difference(n);
      remainingLabel = _fmtRemaining(until, prefix: 'starts in');
      phaseLabel = 'Before work';
    } else if (n.isAfter(workEnd)) {
      remainingLabel = 'Work ended';
      phaseLabel = 'After hours';
    } else {
      final until = workEnd.difference(n);
      remainingLabel = _fmtRemaining(until, prefix: 'ends in');
      phaseLabel = 'In work';
    }

    String? nextBreak;
    final nowMins = n.hour * 60 + n.minute;
    final upcoming = settings.customReminders
        .where((r) => r.enabled && r.minutesOfDay >= nowMins)
        .toList()
      ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    if (upcoming.isNotEmpty) {
      final b = upcoming.first;
      nextBreak = '${b.label} ${b.timeDisplay}';
    }

    return GlanceSnapshot(
      goalsLeft: left,
      goalsTotal: total,
      workEndLabel: settings.workEndDisplay,
      nextBreakLabel: nextBreak,
      remainingLabel: remainingLabel,
      isRestDay: isRest,
      phaseLabel: phaseLabel,
      workStartHour: settings.workStartHour,
      workStartMinute: settings.workStartMinute,
      workEndHour: settings.workEndHour,
      workEndMinute: settings.workEndMinute,
    );
  }

  static String _fmtRemaining(Duration d, {required String prefix}) {
    if (d.isNegative) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$prefix ${h}h ${m}m';
    return '$prefix ${m}m';
  }
}

class GlanceService {
  GlanceService._();
  static final GlanceService instance = GlanceService._();

  static const androidWidgetName = 'DoneDailyWidgetProvider';

  /// Persist snapshot and request an Android widget redraw.
  /// Safe to call often; failures are swallowed so the app never depends on the widget.
  Future<void> update({
    required Daily? daily,
    required AppSettings settings,
  }) async {
    try {
      final snap = GlanceSnapshot.from(daily: daily, settings: settings);
      final data = snap.toWidgetData();
      for (final entry in data.entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e, st) {
      // Widget is optional — never break the app if platform code is missing.
      debugPrint('GlanceService.update skipped: $e\n$st');
    }
  }
}
