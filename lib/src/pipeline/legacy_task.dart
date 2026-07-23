/// Backward-compatibility adapter: wraps legacy [MemoryTask] implementations
/// so they can run as hooks in the new hooks-based [MemoryPipeline].
///
/// ## Overview
///
/// The old pipeline (v0.4.x) used a stream-based model:
///
/// ```dart
/// class MyTask extends MemoryTask {
///   Stream<MemoryTaskEvent> run(MemoryTaskContext context) async* { … }
/// }
/// ```
///
/// The new pipeline (v0.6+) uses a hooks-based model:
///
/// ```dart
/// class MyHook implements RetrievalHook {
///   Future<void> retrieve(PipelineContext context) async { … }
/// }
///
/// final pipeline = MemoryPipeline()
///   ..addHook(myHook);
/// final result = await pipeline.run(query);
/// ```
///
/// These adapters bridge the two worlds so consumers can migrate incrementally.
///
/// ## Usage
///
/// ```dart
/// import 'src/pipeline/memory_task.dart';
/// import 'src/pipeline/legacy_task.dart';
///
/// // Wrap a legacy task as a RetrievalHook
/// final pipeline = MemoryPipeline()
///   ..addHook(LegacyRetrievalTaskAdapter(task: MyLegacyTask()));
///
/// // Or use the extension for a more fluent style:
/// final pipeline = MemoryPipeline()
///   ..addHook(legacyTask.asRetrievalHook());
/// ```
library;

import 'dart:async';

import 'memory_task.dart';
import '../pipeline_hooks.dart';
import '../models/memory_node.dart';

// ---------------------------------------------------------------------------
// Adapter classes
// ---------------------------------------------------------------------------

/// Wraps a legacy [MemoryTask] as a [RetrievalHook].
///
/// The old task's stream events are translated as follows:
///
/// | Old event              | New behaviour                                      |
/// |------------------------|----------------------------------------------------|
/// | `MemoryTaskOutput`     | Converted to a [RetrievedNode] and appended to     |
/// |                        | `context.retrievedNodes`. The output map is stored |
/// |                        | as the node's `metadata`.                          |
/// | `MemoryTaskLog`        | Printed via `print()` (ignored silently otherwise). |
/// | `MemoryTaskContextUpdate` | Merged into `context.metadata`.                 |
/// | `MemoryTaskError`      | Rethrown as a pipeline exception.                  |
class LegacyRetrievalTaskAdapter implements RetrievalHook {
  /// The legacy task to wrap.
  final MemoryTask task;

  /// Priority for the hooks pipeline (lower = runs first).
  @override
  final int priority;

  /// Creates an adapter that exposes [task] as a [RetrievalHook].
  LegacyRetrievalTaskAdapter({required this.task, this.priority = 10});

  @override
  Future<void> retrieve(PipelineContext context) async {
    final oldContext = _toLegacyContext(context);

    try {
      await for (final event in task.run(oldContext)) {
        _handleEvent(event, context);
      }
    } catch (e) {
      // Let unhandled exceptions propagate so the pipeline can treat them
      // as a hook failure.
      rethrow;
    }
  }

  /// Converts the new [PipelineContext] into a legacy [MemoryTaskContext].
  MemoryTaskContext _toLegacyContext(PipelineContext context) {
    return MemoryTaskContext(
      datasetId: context.sessionId,
      metadata: _castMetadata(context.metadata),
    );
  }
}

/// Wraps a legacy [MemoryTask] as an [EnrichmentHook].
///
/// Behaves identically to [LegacyRetrievalTaskAdapter] but implements
/// [EnrichmentHook] so the task runs in the *enrichment* stage rather than
/// the *retrieval* stage of the new pipeline.
class LegacyEnrichmentTaskAdapter implements EnrichmentHook {
  /// The legacy task to wrap.
  final MemoryTask task;

  /// Priority for the hooks pipeline (lower = runs first).
  @override
  final int priority;

  /// Creates an adapter that exposes [task] as an [EnrichmentHook].
  LegacyEnrichmentTaskAdapter({required this.task, this.priority = 10});

  @override
  Future<void> enrich(PipelineContext context) async {
    final oldContext = _toLegacyContext(context);

    try {
      await for (final event in task.run(oldContext)) {
        _handleEvent(event, context);
      }
    } catch (e) {
      rethrow;
    }
  }

  MemoryTaskContext _toLegacyContext(PipelineContext context) {
    return MemoryTaskContext(
      datasetId: context.sessionId,
      metadata: _castMetadata(context.metadata),
    );
  }
}

// ---------------------------------------------------------------------------
// Extension for fluent usage
// ---------------------------------------------------------------------------

/// Extension on legacy [MemoryTask] to produce adapters fluently.
extension LegacyTaskAdapter on MemoryTask {
  /// Returns a [RetrievalHook] that runs this task in the *retrieval* stage.
  RetrievalHook asRetrievalHook({int priority = 10}) {
    return LegacyRetrievalTaskAdapter(task: this, priority: priority);
  }

  /// Returns an [EnrichmentHook] that runs this task in the *enrichment* stage.
  EnrichmentHook asEnrichmentHook({int priority = 10}) {
    return LegacyEnrichmentTaskAdapter(task: this, priority: priority);
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Routes a [MemoryTaskEvent] to the appropriate [PipelineContext] mutation.
void _handleEvent(MemoryTaskEvent event, PipelineContext context) {
  if (event is MemoryTaskOutput) {
    _handleOutput(event, context);
  } else if (event is MemoryTaskContextUpdate) {
    // Merge the old context's metadata into the new pipeline context.
    for (final entry in event.context.metadata.entries) {
      context.metadata[entry.key] = entry.value;
    }
  } else if (event is MemoryTaskError) {
    // Recoverable task errors become pipeline exceptions.
    if (event.error is Error) {
      throw event.error as Error;
    }
    throw Exception(event.error);
  }
  // MemoryTaskLog is intentionally ignored — old tasks may emit verbose
  // logging that would be noisy in the new pipeline.
}

/// Converts a [MemoryTaskOutput] into one or more [RetrievedNode]s and
/// appends them to the pipeline context.
void _handleOutput(MemoryTaskOutput<dynamic> output, PipelineContext context) {
  final raw = output.value;

  if (raw is Map<String, Object?>) {
    // Extract the text content from the output map.
    final content =
        (raw['chunk'] ?? raw['content'] ?? raw['text'] ?? '').toString();
    if (content.isNotEmpty) {
      final node = MemoryNode(
        content: content,
        type: 'legacy',
        metadata: _castMetadata(raw),
      );
      context.retrievedNodes.add(RetrievedNode(
        node: node,
        score: 1.0, // Old tasks don't provide relevance scores.
        source: 'legacy:${output.runtimeType}',
      ));
    }

    // Also merge the output data into metadata so downstream hooks can use it.
    for (final entry in raw.entries) {
      context.metadata[entry.key] = entry.value;
    }
  }
}

/// Bridges `Map<String, Object?>` (legacy) to `Map<String, dynamic>` (new).
///
/// The legacy API uses nullable-typed metadata values while the new pipeline
/// uses `dynamic`. The cast via `.cast()` is safe because `dynamic` accepts
/// every Dart value, including `Object?`.
Map<String, dynamic> _castMetadata(Map<String, Object?> source) {
  return source.cast<String, dynamic>();
}
