import 'dart:async';

import 'memory_task.dart';

/// Event wrapper providing pipeline-level context per task execution.
class MemoryPipelineEvent {
  MemoryPipelineEvent._({
    required this.taskName,
    required this.stage,
    this.taskEvent,
    this.error,
    this.stackTrace,
  });

  /// Name of the task associated with this event.
  final String taskName;

  /// Current pipeline stage.
  final MemoryPipelineStage stage;

  /// Optional underlying task event (logs, outputs, errors, context updates).
  final MemoryTaskEvent? taskEvent;

  /// Error captured when [stage] == [MemoryPipelineStage.failed].
  final Object? error;

  final StackTrace? stackTrace;

  factory MemoryPipelineEvent.taskStarted(String taskName) {
    return MemoryPipelineEvent._(
      taskName: taskName,
      stage: MemoryPipelineStage.started,
    );
  }

  factory MemoryPipelineEvent.taskEvent({
    required String taskName,
    required MemoryTaskEvent event,
  }) {
    return MemoryPipelineEvent._(
      taskName: taskName,
      stage: MemoryPipelineStage.stream,
      taskEvent: event,
    );
  }

  factory MemoryPipelineEvent.taskCompleted(String taskName) {
    return MemoryPipelineEvent._(
      taskName: taskName,
      stage: MemoryPipelineStage.completed,
    );
  }

  factory MemoryPipelineEvent.taskFailed(
    String taskName,
    Object error,
    StackTrace stackTrace,
  ) {
    return MemoryPipelineEvent._(
      taskName: taskName,
      stage: MemoryPipelineStage.failed,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

enum MemoryPipelineStage { started, stream, completed, failed }

/// Executes a list of [MemoryTask] instances sequentially and emits pipeline events.
/// NOTE: Legacy streaming pipeline. For the new hooks-based RAG pipeline
/// see [MemoryPipeline] in pipeline_hooks.dart.
class TaskPipeline {
  TaskPipeline({required List<MemoryTask> tasks})
    : _tasks = List.unmodifiable(tasks);

  final List<MemoryTask> _tasks;

  /// Returns the tasks in this pipeline.
  List<MemoryTask> get tasks => _tasks;

  /// Runs the pipeline and emits [MemoryPipelineEvent]s.
  Stream<MemoryPipelineEvent> run(MemoryTaskContext context) async* {
    MemoryTaskContext currentContext = context;

    for (final task in _tasks) {
      yield MemoryPipelineEvent.taskStarted(task.name);
      try {
        await for (final event in task.run(currentContext)) {
          if (event is MemoryTaskContextUpdate) {
            currentContext = event.context;
          }
          yield MemoryPipelineEvent.taskEvent(
            taskName: task.name,
            event: event,
          );
        }
        yield MemoryPipelineEvent.taskCompleted(task.name);
      } catch (error, stackTrace) {
        yield MemoryPipelineEvent.taskFailed(task.name, error, stackTrace);
        rethrow;
      }
    }
  }
}
