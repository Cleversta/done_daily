// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyAdapter extends TypeAdapter<Daily> {
  @override
  final int typeId = 1;

  @override
  Daily read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Daily(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      goals: (fields[2] as List).cast<Goal>(),
      workEndHour: fields[3] as int,
      isRestDay: fields[4] as bool,
      windDownCompleted: fields[5] as bool,
      notes: fields[6] as String?,
      workEndMinute: fields[7] as int? ?? 0,
      reflection: fields[8] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Daily obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.goals)
      ..writeByte(3)
      ..write(obj.workEndHour)
      ..writeByte(4)
      ..write(obj.isRestDay)
      ..writeByte(5)
      ..write(obj.windDownCompleted)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.workEndMinute)
      ..writeByte(8)
      ..write(obj.reflection);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
