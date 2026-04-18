import 'package:uuid/uuid.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/entities/task.dart' as domain;
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/notification_service.dart';

class GenerateTasksUseCase {
  final TaskRepository _repository;
  final AiService _aiService;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  GenerateTasksUseCase({
    required TaskRepository repository,
    required AiService aiService,
    required NotificationService notificationService,
  })  : _repository = repository,
        _aiService = aiService,
        _notificationService = notificationService;

  Future<List<domain.Task>> execute(String userInput) async {
    final aiTasks = await _aiService.generateTasks(userInput);
    
    final List<domain.Task> tasks = [];
    
    for (final aiTask in aiTasks) {
      final title = aiTask['task'] as String;
      final priorityStr = aiTask['priority'] as String;
      final deadlineStr = aiTask['deadline'] as String?;
      
      DateTime? deadline;
      if (deadlineStr != null && deadlineStr != 'null') {
        try {
          deadline = DateTime.parse(deadlineStr);
        } catch (_) {}
      }
      
      final taskId = _uuid.v4();
      List<int> notificationIds = [];
      
      if (deadline != null && deadline.isAfter(DateTime.now())) {
        notificationIds = await _notificationService.scheduleTaskReminders(
          taskId: taskId,
          taskTitle: title,
          deadline: deadline,
        );
      }
      
      final task = domain.Task(
        id: taskId,
        title: title,
        priority: domain.Task.priorityFromString(priorityStr),
        deadline: deadline,
        notificationIds: notificationIds,
        createdAt: DateTime.now(),
      );
      
      tasks.add(task);
    }
    
    final taskModels = tasks.map(_taskToModel).toList();
    await _repository.addTasks(taskModels);
    
    return tasks;
  }
  
  TaskModel _taskToModel(domain.Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      priority: domain.Task.priorityToString(task.priority),
      deadline: task.deadline,
      isCompleted: task.isCompleted,
      notificationIds: task.notificationIds,
      createdAt: task.createdAt,
    );
  }
}