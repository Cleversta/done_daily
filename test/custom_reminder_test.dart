import 'package:flutter_test/flutter_test.dart';
import 'package:done_daily/models/custom_reminder.dart';
import 'package:done_daily/models/settings_model.dart';

void main() {
  group('CustomReminder', () {
    test('nextId starts at idBase and increments past the highest id', () {
      expect(CustomReminder.nextId(const []), CustomReminder.idBase);

      final existing = [
        const CustomReminder(id: 100, label: 'Lunch', hour: 12, minute: 30),
        const CustomReminder(id: 103, label: 'Stretch', hour: 15, minute: 0),
      ];
      expect(CustomReminder.nextId(existing), 104);
    });

    test('ids never collide with the fixed reminder ids', () {
      expect(CustomReminder.idBase, greaterThan(3));
    });

    test('timeDisplay formats 12-hour time', () {
      expect(
        const CustomReminder(id: 100, label: 'Lunch', hour: 12, minute: 5).timeDisplay,
        '12:05 PM',
      );
      expect(
        const CustomReminder(id: 101, label: 'Early', hour: 0, minute: 0).timeDisplay,
        '12:00 AM',
      );
      expect(
        const CustomReminder(id: 102, label: 'Coffee', hour: 15, minute: 45).timeDisplay,
        '3:45 PM',
      );
    });

    test('json round-trips', () {
      const reminder = CustomReminder(
        id: 105,
        label: 'Walk',
        hour: 14,
        minute: 20,
        enabled: false,
      );
      final decoded = CustomReminder.fromJson(reminder.toJson(), fallbackId: 999);

      expect(decoded.id, 105);
      expect(decoded.label, 'Walk');
      expect(decoded.hour, 14);
      expect(decoded.minute, 20);
      expect(decoded.enabled, isFalse);
    });

    test('fromJson falls back for malformed entries', () {
      final decoded = CustomReminder.fromJson(const {}, fallbackId: 100);

      expect(decoded.id, 100);
      expect(decoded.label, 'Reminder');
      expect(decoded.enabled, isTrue);
    });

    test('copyWith only replaces the given fields', () {
      const reminder = CustomReminder(id: 100, label: 'Lunch', hour: 12, minute: 0);
      final updated = reminder.copyWith(enabled: false, hour: 13);

      expect(updated.id, 100);
      expect(updated.label, 'Lunch');
      expect(updated.hour, 13);
      expect(updated.minute, 0);
      expect(updated.enabled, isFalse);
    });
  });

  group('AppSettings.customReminders', () {
    test('defaults to empty', () {
      expect(const AppSettings().customReminders, isEmpty);
    });

    test('copyWith keeps existing reminders when omitted', () {
      const reminders = [CustomReminder(id: 100, label: 'Lunch', hour: 12, minute: 0)];
      const settings = AppSettings(customReminders: reminders);

      expect(settings.copyWith(isDarkMode: true).customReminders, reminders);
      expect(settings.copyWith(customReminders: const []).customReminders, isEmpty);
    });
  });
}
