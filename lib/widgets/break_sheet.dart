import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../models/custom_reminder.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Shared bottom sheet for adding / editing a break window (start → end).
/// Used from the Today home screen and from Settings.
class BreakSheet {
  BreakSheet._();

  static Future<void> show(
    BuildContext context, {
    CustomReminder? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: _BreakSheetBody(existing: existing),
      ),
    );
  }
}

class _BreakSheetBody extends StatefulWidget {
  final CustomReminder? existing;
  const _BreakSheetBody({this.existing});

  @override
  State<_BreakSheetBody> createState() => _BreakSheetBodyState();
}

class _BreakSheetBodyState extends State<_BreakSheetBody> {
  late final TextEditingController _labelCtrl;
  late TimeOfDay _start;
  late TimeOfDay _end;
  String? _error;

  static const _presets = <({String label, int sh, int sm, int eh, int em})>[
    (label: 'Coffee', sh: 10, sm: 0, eh: 10, em: 15),
    (label: 'Lunch', sh: 12, sm: 0, eh: 13, em: 0),
    (label: 'Afternoon break', sh: 15, sm: 0, eh: 15, em: 15),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _start = e != null
        ? TimeOfDay(hour: e.hour, minute: e.minute)
        : const TimeOfDay(hour: 12, minute: 0);
    _end = e != null && e.hasEnd
        ? TimeOfDay(hour: e.endHour!, minute: e.endMinute!)
        : const TimeOfDay(hour: 13, minute: 0);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  String _fmt(TimeOfDay t) {
    final h = t.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${t.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start,
      builder: _theme,
    );
    if (picked == null) return;
    setState(() {
      _start = picked;
      // Keep a sensible default end (at least 15 min after start)
      if (_mins(_end) <= _mins(_start)) {
        final next = _mins(_start) + 30;
        _end = TimeOfDay(hour: (next ~/ 60) % 24, minute: next % 60);
      }
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end,
      builder: _theme,
    );
    if (picked == null) return;
    setState(() {
      _end = picked;
      _error = null;
    });
  }

  Widget _theme(BuildContext ctx, Widget? child) {
    final t = NTheme.of(ctx);
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: isDark
            ? ColorScheme.dark(
                primary: t.accent,
                onPrimary: Colors.white,
                surface: t.surface,
                onSurface: t.textPrimary,
              )
            : ColorScheme.light(
                primary: t.accent,
                onPrimary: Colors.white,
                surface: t.background,
                onSurface: t.textPrimary,
              ),
      ),
      child: child!,
    );
  }

  void _applyPreset(({String label, int sh, int sm, int eh, int em}) p) {
    setState(() {
      _labelCtrl.text = p.label;
      _start = TimeOfDay(hour: p.sh, minute: p.sm);
      _end = TimeOfDay(hour: p.eh, minute: p.em);
      _error = null;
    });
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Give this break a name');
      return;
    }
    if (_mins(_end) <= _mins(_start)) {
      setState(() => _error = 'End time must be after start');
      return;
    }

    final settingsBloc = context.read<SettingsBloc>();
    final settings = settingsBloc.current;
    final list = [...settings.customReminders];

    if (widget.existing != null) {
      final id = widget.existing!.id;
      final idx = list.indexWhere((r) => r.id == id);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(
          label: label,
          hour: _start.hour,
          minute: _start.minute,
          endHour: _end.hour,
          endMinute: _end.minute,
        );
      }
    } else {
      list.add(CustomReminder(
        id: CustomReminder.nextId(list),
        label: label,
        hour: _start.hour,
        minute: _start.minute,
        endHour: _end.hour,
        endMinute: _end.minute,
      ));
    }

    settingsBloc.add(UpdateSettingsEvent(settings.copyWith(customReminders: list)));
    if (settings.notificationsEnabled) {
      await NotificationService.instance.syncCustomReminders(list);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final settingsBloc = context.read<SettingsBloc>();
    final settings = settingsBloc.current;
    final list = settings.customReminders.where((r) => r.id != existing.id).toList();
    settingsBloc.add(UpdateSettingsEvent(settings.copyWith(customReminders: list)));
    await NotificationService.instance.cancelCustomReminder(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit break' : 'Add a break',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                final s = state is SettingsLoaded ? state.settings : const AppSettings();
                return Text(
                  'Pick a window in your work day (${s.workWindowDisplay}). You’ll get a reminder when it starts.',
                  style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.35),
                );
              },
            ),
            const SizedBox(height: 16),

            // Quick presets (add only)
            if (!isEdit) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in _presets) ...[
                      _PresetChip(
                        label: p.label,
                        time: '${_fmt(TimeOfDay(hour: p.sh, minute: p.sm)).replaceAll(' ', '')}–${_fmt(TimeOfDay(hour: p.eh, minute: p.em)).replaceAll(' ', '')}',
                        onTap: () => _applyPreset(p),
                        t: t,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _labelCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Name (e.g. Lunch, Coffee)',
                filled: true,
                fillColor: t.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    title: 'Starts',
                    value: _fmt(_start),
                    onTap: _pickStart,
                    t: t,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: t.textTertiary),
                ),
                Expanded(
                  child: _TimeTile(
                    title: 'Ends',
                    value: _fmt(_end),
                    onTap: _pickEnd,
                    t: t,
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(fontSize: 13, color: t.danger)),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                if (isEdit)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: t.danger),
                    child: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: t.textSecondary)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.large),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(isEdit ? 'Save' : 'Add break'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final NTheme t;

  const _TimeTile({
    required this.title,
    required this.value,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Text(title, style: TextStyle(fontSize: 11, color: t.textTertiary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: t.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.textPrimary),
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

class _PresetChip extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  final NTheme t;

  const _PresetChip({
    required this.label,
    required this.time,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: t.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textPrimary)),
            Text(time, style: TextStyle(fontSize: 10, color: t.textTertiary)),
          ],
        ),
      ),
    );
  }
}

/// Compact list of breaks for the Today reminder bar.
class BreaksBar extends StatelessWidget {
  const BreaksBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final s = state is SettingsLoaded ? state.settings : const AppSettings();
        final t = NTheme.of(context);
        final breaks = [...s.customReminders]
          ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Breaks',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: t.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => BreakSheet.show(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: t.accent),
                      const SizedBox(width: 2),
                      Text(
                        'Add',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (breaks.isEmpty)
              GestureDetector(
                onTap: () => BreakSheet.show(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    boxShadow: t.boxShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.free_breakfast_outlined, size: 18, color: t.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No breaks yet — add lunch or a coffee break',
                          style: TextStyle(fontSize: 13, color: t.textSecondary),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: t.textTertiary),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: breaks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final b = breaks[i];
                    return _BreakChip(
                      reminder: b,
                      onTap: () => BreakSheet.show(context, existing: b),
                      t: t,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BreakChip extends StatelessWidget {
  final CustomReminder reminder;
  final VoidCallback onTap;
  final NTheme t;

  const _BreakChip({
    required this.reminder,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final muted = !reminder.enabled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppRadii.large),
          boxShadow: t.boxShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.free_breakfast_outlined,
                  size: 14,
                  color: muted ? t.textTertiary : t.accent,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    reminder.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: muted ? t.textTertiary : t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              reminder.windowDisplay,
              style: TextStyle(
                fontSize: 11,
                color: muted ? t.textTertiary : t.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
