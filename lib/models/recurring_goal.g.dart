// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'recurring_goal.dart';

class RecurringGoalAdapter extends TypeAdapter<RecurringGoal> {
  @override
  final int typeId = 3;

  @override
  RecurringGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringGoal(
      id: fields[0] as String,
      title: fields[1] as String,
      isPriority: fields[2] as bool? ?? false,
      days: (fields[3] as List?)?.cast<int>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, RecurringGoal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isPriority)
      ..writeByte(3)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
