import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../../../../core/constants/api_constants.dart';

class TaskRepository {
  late Box<TaskModel> _tasksBox;
  
  Future<void> initialize() async {
    _tasksBox = await Hive.openBox<TaskModel>(StorageKeys.tasksBox);
  }
  
  List<TaskModel> getAllTasks() {
    return _tasksBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  List<TaskModel> getPendingTasks() {
    return getAllTasks().where((task) => !task.isCompleted).toList();
  }
  
  List<TaskModel> getCompletedTasks() {
    return getAllTasks().where((task) => task.isCompleted).toList();
  }
  
  Future<void> addTask(TaskModel task) async {
    await _tasksBox.put(task.id, task);
  }
  
  Future<void> addTasks(List<TaskModel> tasks) async {
    final Map<String, TaskModel> taskMap = {
      for (final task in tasks) task.id: task
    };
    await _tasksBox.putAll(taskMap);
  }
  
  Future<void> updateTask(TaskModel task) async {
    await _tasksBox.put(task.id, task);
  }
  
  Future<void> deleteTask(String taskId) async {
    await _tasksBox.delete(taskId);
  }
  
  Future<void> clearAllTasks() async {
    await _tasksBox.clear();
  }
  
  TaskModel? getTask(String taskId) {
    return _tasksBox.get(taskId);
  }
}