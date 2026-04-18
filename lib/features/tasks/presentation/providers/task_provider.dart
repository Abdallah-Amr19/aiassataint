import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import '../../domain/entities/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';
import '../../domain/usecases/generate_tasks.dart';
import '../../domain/usecases/complete_task.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/constants/api_constants.dart';

final apiKeyProvider = StateProvider<String>(
  (ref) => ApiConstants.defaultCohereApiKey,
);

final elevenLabsApiKeyProvider = StateProvider<String>(
  (ref) => ApiConstants.defaultElevenLabsApiKey,
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  throw UnimplementedError('Must be overridden');
});

final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  final elevenLabsKey = ref.watch(elevenLabsApiKeyProvider);
  return AiService(
    cohereApiKey: apiKey,
    elevenLabsApiKey: elevenLabsKey.isEmpty ? null : elevenLabsKey,
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final generateTasksUseCaseProvider = Provider<GenerateTasksUseCase>((ref) {
  return GenerateTasksUseCase(
    repository: ref.watch(taskRepositoryProvider),
    aiService: ref.watch(aiServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(
    repository: ref.watch(taskRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final bool isRecording;
  final String? transcribedText;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.isRecording = false,
    this.transcribedText,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    bool? isRecording,
    String? transcribedText,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRecording: isRecording ?? this.isRecording,
      transcribedText: transcribedText,
    );
  }

  List<Task> get pendingTasks => tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => tasks.where((t) => t.isCompleted).toList();
}

class TaskNotifier extends StateNotifier<TaskState> {
  final TaskRepository _repository;
  final GenerateTasksUseCase _generateTasksUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final AiService _aiService;
  final AudioRecorder _recorder = AudioRecorder();

  TaskNotifier(
    this._repository,
    this._generateTasksUseCase,
    this._completeTaskUseCase,
    this._aiService,
  ) : super(const TaskState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final taskModels = _repository.getAllTasks();
    final tasks = taskModels.map(_modelToTask).toList();
    state = state.copyWith(tasks: tasks);
  }

  Future<void> generateTasks(String input) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newTasks = await _generateTasksUseCase.execute(input);
      final allTasks = [...state.tasks, ...newTasks];
      state = state.copyWith(tasks: allTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      await _completeTaskUseCase.execute(taskId);
      final tasks = state.tasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(isCompleted: true, notificationIds: []);
        }
        return t;
      }).toList();
      state = state.copyWith(tasks: tasks);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
    final tasks = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(tasks: tasks);
  }

  Future<void> clearCompleted() async {
    final completedIds = completedTasks.map((t) => t.id).toList();
    for (final id in completedIds) {
      await _repository.deleteTask(id);
    }
    final tasks = state.tasks.where((t) => !t.isCompleted).toList();
    state = state.copyWith(tasks: tasks);
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: 'Microphone permission denied');
        return;
      }
      await _recorder.start(const RecordConfig(), path: '');
      state = state.copyWith(
        isRecording: true,
        transcribedText: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Recording error: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _recorder.stop();
      state = state.copyWith(isRecording: false);

      if (path == null || path.isEmpty) {
        state = state.copyWith(error: 'No audio recorded');
        return;
      }

      state = state.copyWith(isLoading: true);

      try {
        if (_aiService.elevenLabsApiKey == null ||
            _aiService.elevenLabsApiKey!.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Set ElevenLabs API key in Settings',
          );
          return;
        }

        final text = await _aiService.transcribeAudio(path);
        if (text != null && text.isNotEmpty) {
          state = state.copyWith(isLoading: false, transcribedText: text);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Could not understand audio',
          );
        }
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Transcription failed: $e',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Recording error: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  List<Task> get pendingTasks => state.pendingTasks;
  List<Task> get completedTasks => state.completedTasks;

  Task _modelToTask(TaskModel model) {
    return Task(
      id: model.id,
      title: model.title,
      priority: Task.priorityFromString(model.priority),
      deadline: model.deadline,
      isCompleted: model.isCompleted,
      notificationIds: model.notificationIds,
      createdAt: model.createdAt,
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final generateTasksUseCase = ref.watch(generateTasksUseCaseProvider);
  final completeTaskUseCase = ref.watch(completeTaskUseCaseProvider);
  final aiService = ref.watch(aiServiceProvider);

  return TaskNotifier(
    repository,
    generateTasksUseCase,
    completeTaskUseCase,
    aiService,
  );
});
