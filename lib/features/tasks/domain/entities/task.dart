enum TaskPriority { high, medium, low }

class Task {
  final String id;
  final String title;
  final TaskPriority priority;
  final DateTime? deadline;
  final bool isCompleted;
  final List<int> notificationIds;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.deadline,
    this.isCompleted = false,
    this.notificationIds = const [],
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    DateTime? deadline,
    bool? isCompleted,
    List<int>? notificationIds,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationIds: notificationIds ?? this.notificationIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasDeadline => deadline != null;
  
  bool get isOverdue => deadline != null && deadline!.isBefore(DateTime.now()) && !isCompleted;
  
  bool get isDueSoon => deadline != null && 
      deadline!.isAfter(DateTime.now()) && 
      deadline!.difference(DateTime.now()).inMinutes <= 60;

  static TaskPriority priorityFromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
  
  static String priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }
}