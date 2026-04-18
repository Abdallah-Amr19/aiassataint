import 'package:hive/hive.dart';

class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String priority;

  @HiveField(3)
  final DateTime? deadline;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  final List<int> notificationIds;

  @HiveField(6)
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    this.deadline,
    this.isCompleted = false,
    this.notificationIds = const [],
    required this.createdAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? priority,
    DateTime? deadline,
    bool? isCompleted,
    List<int>? notificationIds,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationIds: notificationIds ?? this.notificationIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
      'notificationIds': notificationIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : null,
      isCompleted: json['isCompleted'] ?? false,
      notificationIds: List<int>.from(json['notificationIds'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}