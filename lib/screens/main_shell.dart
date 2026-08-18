import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/daily_bloc.dart';
import '../bloc/daily_event.dart';
import '../bloc/daily_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'daily_screen.dart';
import 'archive_screen.dart';
import 'summary_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _lastLoadedDate = '';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _lastLoadedDate = _todayKey();
    WidgetsBinding.instance.addObserver(this);
    // Wait for the first frame so the Activity is in RESUMED state before
    // showing the system permission dialog — calling earlier drops it silently.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _askNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _todayKey();
      if (today != _lastLoadedDate) {
        _lastLoadedDate = today;
        context.read<DailyBloc>().add(const LoadDailyEvent());
      }
    }
  }

  Future<void> _askNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isDenied) return; // granted, permanently denied, or restricted — nothing to do

    final result = await Permission.notification.request();
    if (!mounted || !result.isGranted) return;

    final settingsBloc = context.read<SettingsBloc>();
    final current = settingsBloc.current;
    if (current.notificationsEnabled) return; // already on

    final updated = current.copyWith(notificationsEnabled: true);
    settingsBloc.add(UpdateSettingsEvent(updated));
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

  void _onTap(int index) {
    if (index == 0 && _currentIndex != 0) {
      final bloc = context.read<DailyBloc>();
      final today = _todayKey();
      // Always reload if state isn't already today's loaded daily,
      // but skip the reload if we just updated state (e.g. added a goal from Recap)
      // to avoid a race condition that would overwrite the new state.
      if (bloc.state is! DailyLoaded || today != _lastLoadedDate) {
        _lastLoadedDate = today;
        bloc.add(const LoadDailyEvent());
      }
    }
    setState(() => _currentIndex = index);
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const DailyScreen();
      case 1:
        return const ArchiveScreen();
      case 2:
        return const SummaryScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const DailyScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = NTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      resizeToAvoidBottomInset: false,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: t.background,
          boxShadow: [
            BoxShadow(color: t.shadowDark, blurRadius: 16, offset: const Offset(0, -4)),
            BoxShadow(color: t.shadowLight, blurRadius: 4, offset: const Offset(0, -1)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.today_outlined),
              activeIcon: Icon(Icons.today),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize_outlined),
              activeIcon: Icon(Icons.summarize),
              label: 'Recap',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
