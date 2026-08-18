import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../models/custom_reminder.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../services/backup_service.dart';

const _appId = 'com.cleversta.done_daily';
const _playStoreUrl = 'https://play.google.com/store/apps/details?id=$_appId';
const _playStoreRateUrl = 'market://details?id=$_appId';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Tracks whether a permission request is in progress to prevent double-taps.
  bool _requestingPermission = false;

  void _shareApp() {
    Share.share(
      'Check out DONE:Daily — a simple daily goal tracker that gives you a real finish line every day.\n\n$_playStoreUrl',
      subject: 'DONE:Daily app',
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (url == _playStoreRateUrl) {
      await launchUrl(Uri.parse(_playStoreUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final count = await BackupService.instance.importData();
      if (!mounted) return;
      if (count == -1) return;
      context.read<DailyBloc>().add(const LoadDailyEvent());
      context.read<SettingsBloc>().add(const InitializeSettingsEvent());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored $count days of data.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Could not read backup file. Make sure it's a valid DONE:Daily backup."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _update(AppSettings s) {
    context.read<SettingsBloc>().add(UpdateSettingsEvent(s));
  }

  // Called when the master notifications toggle is flipped ON.
  // Requests system permission first; falls back gracefully if denied.
  Future<void> _enableNotifications(AppSettings settings) async {
    if (_requestingPermission) return;

    // If permanently denied, skip the request and go straight to device Settings.
    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notifications blocked. Open device Settings to allow them.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
          backgroundColor: AppColors.textPrimary,
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: AppColors.background,
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    setState(() => _requestingPermission = true);
    final granted = await NotificationService.instance.requestPermissions();

    if (!mounted) return;
    setState(() => _requestingPermission = false);

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification permission denied.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
          backgroundColor: AppColors.textPrimary,
        ),
      );
      return;
    }

    final updated = settings.copyWith(notificationsEnabled: true);
    _update(updated);
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
    );
  }

  Future<void> _disableNotifications(AppSettings settings) async {
    _update(settings.copyWith(notificationsEnabled: false));
    await NotificationService.instance.cancelAll();
  }

  Future<void> _pickWorkEndTime(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.workEndHour, minute: settings.workEndMinute),
      builder: (ctx, child) => _timepickerTheme(ctx, child),
    );
    if (picked == null || !mounted) return;
    final updated = settings.copyWith(workEndHour: picked.hour, workEndMinute: picked.minute);
    _update(updated);
    context.read<DailyBloc>().add(SetWorkEndTimeEvent(hour: picked.hour, minute: picked.minute));
    if (settings.notificationsEnabled && settings.workEndNotificationEnabled) {
      await NotificationService.instance.scheduleWorkEndNotification(picked.hour, picked.minute);
    }
  }

  Future<void> _pickMorningTime(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.morningReminderHour, minute: settings.morningReminderMinute),
      builder: (ctx, child) => _timepickerTheme(ctx, child),
    );
    if (picked == null || !mounted) return;
    final updated = settings.copyWith(morningReminderHour: picked.hour, morningReminderMinute: picked.minute);
    _update(updated);
    if (settings.notificationsEnabled && settings.morningReminderEnabled) {
      await NotificationService.instance.scheduleMorningReminder(picked.hour, picked.minute);
    }
  }

  Future<void> _pickWeeklyTime(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.weeklyReminderHour, minute: settings.weeklyReminderMinute),
      builder: (ctx, child) => _timepickerTheme(ctx, child),
    );
    if (picked == null || !mounted) return;
    final updated = settings.copyWith(weeklyReminderHour: picked.hour, weeklyReminderMinute: picked.minute);
    _update(updated);
    if (settings.notificationsEnabled && settings.weeklyReminderEnabled) {
      await NotificationService.instance.scheduleWeeklySummary(picked.hour, picked.minute);
    }
  }

  Future<void> _toggleWorkEndNotification(AppSettings settings, bool value) async {
    _update(settings.copyWith(workEndNotificationEnabled: value));
    if (settings.notificationsEnabled) {
      if (value) {
        await NotificationService.instance.scheduleWorkEndNotification(
            settings.workEndHour, settings.workEndMinute);
      } else {
        await NotificationService.instance.cancelWorkEnd();
      }
    }
  }

  Future<void> _toggleMorningNotification(AppSettings settings, bool value) async {
    _update(settings.copyWith(morningReminderEnabled: value));
    if (settings.notificationsEnabled) {
      if (value) {
        await NotificationService.instance.scheduleMorningReminder(
            settings.morningReminderHour, settings.morningReminderMinute);
      } else {
        await NotificationService.instance.cancelMorning();
      }
    }
  }

  Future<void> _toggleWeeklyNotification(AppSettings settings, bool value) async {
    _update(settings.copyWith(weeklyReminderEnabled: value));
    if (settings.notificationsEnabled) {
      if (value) {
        await NotificationService.instance.scheduleWeeklySummary(
            settings.weeklyReminderHour, settings.weeklyReminderMinute);
      } else {
        await NotificationService.instance.cancelWeekly();
      }
    }
  }

  List<CustomReminder> _sortedReminders(AppSettings settings) {
    final list = [...settings.customReminders];
    list.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return list;
  }

  Future<void> _saveReminders(AppSettings settings, List<CustomReminder> reminders) async {
    _update(settings.copyWith(customReminders: reminders));
    if (settings.notificationsEnabled) {
      await NotificationService.instance.syncCustomReminders(reminders);
    }
  }

  Future<void> _addCustomReminder(AppSettings settings) async {
    final result = await _showReminderDialog();
    if (result == null) return;
    final reminder = CustomReminder(
      id: CustomReminder.nextId(settings.customReminders),
      label: result.label,
      hour: result.time.hour,
      minute: result.time.minute,
    );
    await _saveReminders(settings, [...settings.customReminders, reminder]);
  }

  Future<void> _editCustomReminder(AppSettings settings, CustomReminder reminder) async {
    final result = await _showReminderDialog(existing: reminder);
    if (result == null) return;
    final updated = settings.customReminders
        .map((r) => r.id == reminder.id
            ? r.copyWith(label: result.label, hour: result.time.hour, minute: result.time.minute)
            : r)
        .toList();
    await _saveReminders(settings, updated);
  }

  Future<void> _toggleCustomReminder(AppSettings settings, CustomReminder reminder, bool value) async {
    final updated = settings.customReminders
        .map((r) => r.id == reminder.id ? r.copyWith(enabled: value) : r)
        .toList();
    await _saveReminders(settings, updated);
  }

  Future<void> _deleteCustomReminder(AppSettings settings, CustomReminder reminder) async {
    final updated = settings.customReminders.where((r) => r.id != reminder.id).toList();
    _update(settings.copyWith(customReminders: updated));
    await NotificationService.instance.cancelCustomReminder(reminder.id);
  }

  // Label + time editor shared by add and edit.
  Future<({String label, TimeOfDay time})?> _showReminderDialog({CustomReminder? existing}) async {
    final controller = TextEditingController(text: existing?.label ?? '');
    var time = existing == null
        ? const TimeOfDay(hour: 13, minute: 0)
        : TimeOfDay(hour: existing.hour, minute: existing.minute);

    final result = await showDialog<({String label, TimeOfDay time})>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final t = NTheme.of(dialogContext);
            return AlertDialog(
              backgroundColor: t.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
              title: Text(existing == null ? 'New reminder' : 'Edit reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Label (e.g. Lunch break)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: time,
                        builder: (ctx, child) => _timepickerTheme(ctx, child),
                      );
                      if (picked != null) setDialogState(() => time = picked);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 20, color: t.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Time',
                            style: Theme.of(dialogContext).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          time.format(dialogContext),
                          style: Theme.of(dialogContext)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: t.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final label = controller.text.trim();
                    if (label.isEmpty) return;
                    Navigator.of(dialogContext).pop((label: label, time: time));
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Widget _timepickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.textPrimary,
          onPrimary: AppColors.background,
          surface: AppColors.background,
        ),
      ),
      child: child!,
    );
  }

  void _showPrivacySheet(BuildContext context) {
    final t = NTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final t = NTheme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),
              Text('Privacy', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 20),

              Text('YOUR DATA STAYS ON YOUR DEVICE',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                'Everything you write — goals, reflections, habits — is stored only on your phone. Nothing is ever sent to a server, shared with third parties, or stored in the cloud.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: 16),

              Text('NO ACCOUNT REQUIRED',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                'DONE:Daily works completely offline. There is no login, no profile, and no way for anyone to access your data except you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: 16),

              Text('NO TRACKING OR ANALYTICS',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                'We don\'t collect usage data, crash reports, or analytics. The app has no internet permission.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: 16),

              Text('BACKUP',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                'You can export your data anytime from this screen. The export is a plain JSON file that only you control.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHowToUseSheet(BuildContext context) {
    final t = NTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.background,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final t = NTheme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),
              Text('How to use', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 20),

              _HowToTip(
                icon: Icons.add_circle_outline,
                title: 'Adding goals',
                body: 'Tap + to add a goal for today. Tap the star to mark it as priority — priority goals appear at the top. Long-press any goal to drag and reorder.',
              ),
              const SizedBox(height: 16),

              _HowToTip(
                icon: Icons.repeat_rounded,
                title: 'Recurring goals',
                body: 'When adding a goal, tap the Repeat toggle to make it a habit. Choose which days it appears, or leave all unselected for every day. Recurring goals auto-appear each morning.',
              ),
              const SizedBox(height: 16),

              _HowToTip(
                icon: Icons.timer_outlined,
                title: 'Focus timer',
                body: 'Tap the ▶ button on any goal to start a focus session. Pick a duration and work without distraction. Tap \'Mark Done\' when finished.',
              ),
              const SizedBox(height: 16),

              _HowToTip(
                icon: Icons.wb_sunny_outlined,
                title: 'Carry-over',
                body: 'If you didn\'t finish all your goals yesterday, a banner will appear offering to carry them into today. Tap Add to bring them over, or dismiss to start fresh.',
              ),
              const SizedBox(height: 16),

              _HowToTip(
                icon: Icons.edit_note_rounded,
                title: 'Daily reflection',
                body: 'At the bottom of Today, write a few words about how the day went. These notes are saved and visible when you tap any past day in the Archive.',
              ),
              const SizedBox(height: 16),

              _HowToTip(
                icon: Icons.bar_chart_rounded,
                title: 'Archive',
                body: 'Tap the Archive tab to see your history. Use ‹ › to browse months. Tap any day in the calendar for the full breakdown.',
              ),
              const SizedBox(height: 16),

              _HowToTip(
                icon: Icons.download_outlined,
                title: 'Backup',
                body: 'Go to Settings → About → Export data to save all your data as a JSON file. Keep it in Google Drive or email it to yourself.',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state is SettingsLoaded ? state.settings : const AppSettings();

        return Scaffold(
          backgroundColor: t.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              children: [
                Text('Settings', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 28),

                // ── Appearance ─────────────────────────────────────────
                _SectionLabel('APPEARANCE'),
                const SizedBox(height: 10),

                _Card(
                  child: _SwitchRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark mode',
                    value: settings.isDarkMode,
                    onChanged: (v) => _update(settings.copyWith(isDarkMode: v)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Notifications ──────────────────────────────────────
                _SectionLabel('NOTIFICATIONS'),
                const SizedBox(height: 10),

                _Card(
                  child: Column(
                    children: [
                      // Master toggle
                      _SwitchRow(
                        icon: Icons.notifications_outlined,
                        label: 'All notifications',
                        subtitle: settings.notificationsEnabled
                            ? 'Tap individual toggles below'
                            : 'Tap to enable — system permission will be asked',
                        value: settings.notificationsEnabled,
                        loading: _requestingPermission,
                        onChanged: (v) {
                          if (v) {
                            _enableNotifications(settings);
                          } else {
                            _disableNotifications(settings);
                          }
                        },
                      ),

                      if (settings.notificationsEnabled) ...[
                        const _Divider(),

                        // Work end notification
                        _SwitchRow(
                          icon: Icons.alarm_outlined,
                          label: 'Work end reminder',
                          subtitle: 'Notifies you when work time arrives',
                          value: settings.workEndNotificationEnabled,
                          onChanged: (v) => _toggleWorkEndNotification(settings, v),
                        ),

                        if (settings.workEndNotificationEnabled) ...[
                          const _Divider(),
                          _SettingRow(
                            icon: Icons.schedule_outlined,
                            label: 'End reminder time',
                            value: settings.workEndDisplay,
                            onTap: () => _pickWorkEndTime(settings),
                          ),
                        ],

                        const _Divider(),

                        // Morning reminder
                        _SwitchRow(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Morning reminder',
                          subtitle: 'Prompts you to set your goals each day',
                          value: settings.morningReminderEnabled,
                          onChanged: (v) => _toggleMorningNotification(settings, v),
                        ),

                        if (settings.morningReminderEnabled) ...[
                          const _Divider(),
                          _SettingRow(
                            icon: Icons.access_time_outlined,
                            label: 'Start reminder time',
                            value: settings.morningReminderDisplay,
                            onTap: () => _pickMorningTime(settings),
                          ),
                        ],

                        const _Divider(),

                        // Weekly summary
                        _SwitchRow(
                          icon: Icons.calendar_view_week_outlined,
                          label: 'Weekly summary',
                          subtitle: 'Sunday evening recap of your week',
                          value: settings.weeklyReminderEnabled,
                          onChanged: (v) => _toggleWeeklyNotification(settings, v),
                        ),

                        if (settings.weeklyReminderEnabled) ...[
                          const _Divider(),
                          _SettingRow(
                            icon: Icons.access_time_outlined,
                            label: 'Summary reminder time',
                            value: settings.weeklyReminderDisplay,
                            onTap: () => _pickWeeklyTime(settings),
                          ),
                        ],

                        // Custom reminders between morning and work end
                        for (final reminder in _sortedReminders(settings)) ...[
                          const _Divider(),
                          _CustomReminderRow(
                            reminder: reminder,
                            onTap: () => _editCustomReminder(settings, reminder),
                            onChanged: (v) => _toggleCustomReminder(settings, reminder, v),
                            onDelete: () => _deleteCustomReminder(settings, reminder),
                          ),
                        ],

                        const _Divider(),
                        _SettingRow(
                          icon: Icons.add_alarm_outlined,
                          label: 'Add reminder',
                          value: '',
                          onTap: () => _addCustomReminder(settings),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── About ──────────────────────────────────────────────
                _SectionLabel('ABOUT'),
                const SizedBox(height: 10),

                // Mission card
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DONE:Daily',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Built for people who work hard and deserve real rest.\n\nNo infinite task lists. No guilt. Just a clear finish line every single day.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: t.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Info rows card
                _Card(
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.info_outline,
                        label: 'Version',
                        value: '1.0.0',
                        onTap: null,
                      ),
                      const _Divider(),
                      _SettingRow(
                        icon: Icons.lock_outline,
                        label: 'Privacy',
                        value: '',
                        onTap: () => _showPrivacySheet(context),
                      ),
                      const _Divider(),
                      _SettingRow(
                        icon: Icons.help_outline_rounded,
                        label: 'How to use',
                        value: '',
                        onTap: () => _showHowToUseSheet(context),
                      ),
                      const _Divider(),
                      _SettingRow(
                        icon: Icons.download_outlined,
                        label: 'Export data',
                        value: '',
                        onTap: () => BackupService.instance.exportData(),
                      ),
                      const _Divider(),
                      _SettingRow(
                        icon: Icons.upload_outlined,
                        label: 'Restore backup',
                        value: '',
                        onTap: _restoreBackup,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Share / Rate / Developer card
                _Card(
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.share_outlined,
                        label: 'Share app',
                        value: '',
                        onTap: () => _shareApp(),
                      ),
                      const _Divider(),
                      _SettingRow(
                        icon: Icons.star_outline_rounded,
                        label: 'Rate on Play Store',
                        value: '',
                        onTap: () => _openUrl(_playStoreRateUrl),
                      ),
                      const _Divider(),
                      _SettingRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Developer',
                        value: 'marason',
                        onTap: () => _openUrl(_playStoreUrl),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'All data is stored on this device only.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge,
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: t.boxShadow,
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, color: t.shadowDark),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: t.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textSecondary)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: t.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    this.loading = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: t.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
          if (loading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.textSecondary),
            )
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CustomReminderRow extends StatelessWidget {
  final CustomReminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  const _CustomReminderRow({
    required this.reminder,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.alarm_outlined, size: 20, color: t.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(reminder.timeDisplay, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 20, color: t.textTertiary),
            tooltip: 'Delete reminder',
          ),
          Switch(value: reminder.enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ─── How To Use tip widget ────────────────────────────────────────────────────

class _HowToTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HowToTip({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: t.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: t.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
