import '../../data/repositories/task_repository.dart';
import '../../domain/entities/task.dart' as domain;
import '../../../../core/services/notification_service.dart';

class CompleteTaskUseCase {
  final TaskRepository _repository;
  final NotificationService _notificationService;

  CompleteTaskUseCase({
    required TaskRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService;

  Future<domain.Task> execute(String taskId) async {
    final taskModel = _repository.getTask(taskId);

    if (taskModel == null) {
      throw Exception('Task not found');
    }

    await _notificationService.cancelNotifications(taskModel.notificationIds);

    taskModel.isCompleted = true;
    taskModel.notificationIds.clear();

    await _repository.updateTask(taskModel);

    return domain.Task(
      id: taskModel.id,
      title: taskModel.title,
      priority: domain.Task.priorityFromString(taskModel.priority),
      deadline: taskModel.deadline,
      isCompleted: taskModel.isCompleted,
      notificationIds: taskModel.notificationIds,
      createdAt: taskModel.createdAt,
    );
  }
}
