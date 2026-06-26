import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import '../models/settings_model.dart';
import '../services/notification_service.dart';

const _settingsKey = 'app_settings';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  late Box<AppSettings> _box;

  SettingsBloc() : super(const SettingsInitial()) {
    on<InitializeSettingsEvent>(_onInitialize);
    on<UpdateSettingsEvent>(_onUpdate);
  }

  AppSettings get current {
    final s = state;
    return s is SettingsLoaded ? s.settings : const AppSettings();
  }

  Future<void> _onInitialize(InitializeSettingsEvent event, Emitter<SettingsState> emit) async {
    _box = await Hive.openBox<AppSettings>('settings');
    final settings = _box.get(_settingsKey) ?? const AppSettings();
    emit(SettingsLoaded(settings));

    if (settings.notificationsEnabled) {
      final permStatus = await Permission.notification.status;
      if (permStatus.isGranted) {
        // Re-sync after reboot — Android clears all pending alarms on restart.
        await NotificationService.instance.syncNotifications(
          enabled: true,
          workEndEnabled: settings.workEndNotificationEnabled,
          workEndHour: settings.workEndHour,
          workEndMinute: settings.workEndMinute,
          morningEnabled: settings.morningReminderEnabled,
          morningHour: settings.morningReminderHour,
          morningMinute: settings.morningReminderMinute,
          weeklyEnabled: settings.weeklyReminderEnabled,
          weeklyHour: settings.weeklyReminderHour,
          weeklyMinute: settings.weeklyReminderMinute,
        );
      } else {
        // Permission was revoked in device Settings — mirror that in app state.
        final updated = settings.copyWith(notificationsEnabled: false);
        await _box.put(_settingsKey, updated);
        emit(SettingsLoaded(updated));
      }
    }
    // First-launch permission request is handled by MainShell.initState
    // (needs addPostFrameCallback so the Activity is in RESUMED state).
  }

  Future<void> _onUpdate(UpdateSettingsEvent event, Emitter<SettingsState> emit) async {
    await _box.put(_settingsKey, event.settings);
    emit(SettingsLoaded(event.settings));
  }
}
