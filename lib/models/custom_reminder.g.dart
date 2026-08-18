// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-updated to add endHour / endMinute (fields 5 & 6) while remaining
// backward-compatible with older on-device data that only has 5 fields.

part of 'custom_reminder.dart';

class CustomReminderAdapter extends TypeAdapter<CustomReminder> {
  @override
  final int typeId = 4;

  @override
  CustomReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomReminder(
      id: fields[0] as int,
      label: fields[1] as String,
      hour: fields[2] as int,
      minute: fields[3] as int,
      enabled: fields[4] as bool? ?? true,
      endHour: fields[5] as int?,
      endMinute: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomReminder obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.endHour)
      ..writeByte(6)
      ..write(obj.endMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
