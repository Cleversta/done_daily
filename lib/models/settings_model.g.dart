// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-updated for workStart + wrap-up fields (14–17). Backward-compatible.

part of 'settings_model.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      workEndHour: fields[0] as int? ?? 18,
      workEndMinute: fields[1] as int? ?? 0,
      restDays: (fields[2] as List?)?.cast<int>() ?? const [7],
      notificationsEnabled: fields[3] as bool? ?? true,
      morningReminderHour: fields[4] as int? ?? 8,
      morningReminderMinute: fields[5] as int? ?? 0,
      workEndNotificationEnabled: fields[6] as bool? ?? true,
      morningReminderEnabled: fields[7] as bool? ?? true,
      isDarkMode: fields[8] as bool? ?? false,
      weeklyReminderEnabled: fields[9] as bool? ?? false,
      weeklyReminderHour: fields[10] as int? ?? 20,
      weeklyReminderMinute: fields[11] as int? ?? 0,
      hasSeenOnboarding: fields[12] as bool? ?? false,
      customReminders:
          (fields[13] as List?)?.cast<CustomReminder>() ?? const [],
      workStartHour: fields[14] as int? ?? 9,
      workStartMinute: fields[15] as int? ?? 0,
      wrapUpEnabled: fields[16] as bool? ?? true,
      wrapUpMinutesBefore: fields[17] as int? ?? 15,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.workEndHour)
      ..writeByte(1)
      ..write(obj.workEndMinute)
      ..writeByte(2)
      ..write(obj.restDays)
      ..writeByte(3)
      ..write(obj.notificationsEnabled)
      ..writeByte(4)
      ..write(obj.morningReminderHour)
      ..writeByte(5)
      ..write(obj.morningReminderMinute)
      ..writeByte(6)
      ..write(obj.workEndNotificationEnabled)
      ..writeByte(7)
      ..write(obj.morningReminderEnabled)
      ..writeByte(8)
      ..write(obj.isDarkMode)
      ..writeByte(9)
      ..write(obj.weeklyReminderEnabled)
      ..writeByte(10)
      ..write(obj.weeklyReminderHour)
      ..writeByte(11)
      ..write(obj.weeklyReminderMinute)
      ..writeByte(12)
      ..write(obj.hasSeenOnboarding)
      ..writeByte(13)
      ..write(obj.customReminders)
      ..writeByte(14)
      ..write(obj.workStartHour)
      ..writeByte(15)
      ..write(obj.workStartMinute)
      ..writeByte(16)
      ..write(obj.wrapUpEnabled)
      ..writeByte(17)
      ..write(obj.wrapUpMinutesBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
