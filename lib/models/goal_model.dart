import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 0)
class Goal extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final bool isCompleted;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final DateTime? completedAt;

  @HiveField(5)
  final bool isPriority;

  @HiveField(6)
  final String? recurringTemplateId;

  Goal({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.isPriority = false,
    this.recurringTemplateId,
  });

  Goal copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isPriority,
    bool clearCompletedAt = false,
    String? recurringTemplateId,
    bool clearRecurringTemplateId = false,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      isPriority: isPriority ?? this.isPriority,
      recurringTemplateId: clearRecurringTemplateId ? null : recurringTemplateId ?? this.recurringTemplateId,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted, createdAt, completedAt, isPriority, recurringTemplateId];
}
