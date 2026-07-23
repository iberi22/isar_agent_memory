import 'package:meta/meta.dart';

import '../embeddings_adapter.dart';
import '../memory_graph.dart';
import '../models/memory_node.dart';
import '../models/memory_embedding.dart';

/// Shared context passed to every [MemoryTask].
@immutable
class MemoryTaskContext {
  MemoryTaskContext({
    this.datasetId,
    this.metadata = const <String, Object?>{},
  });

  /// Optional dataset identifier associated with the current pipeline run.
  final String? datasetId;

  /// Arbitrary metadata that tasks can read or extend with additional values.
  final Map<String, Object?> metadata;

  MemoryTaskContext copyWith({
    String? datasetId,
    Map<String, Object?>? metadata,
  }) {
    return MemoryTaskContext(
      datasetId: datasetId ?? this.datasetId,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Base event emitted by a [MemoryTask].
@immutable
abstract class MemoryTaskEvent {
  MemoryTaskEvent({DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now().toUtc();

  final DateTime timestamp;
}

/// Structured log message emitted during task execution.
class MemoryTaskLog extends MemoryTaskEvent {
  MemoryTaskLog({
    required this.level,
    required this.message,
    Map<String, Object?>? data,
    super.timestamp,
  }) : data = data ?? const <String, Object?>{};

  final String level;
  final String message;
  final Map<String, Object?> data;
}

/// Task output item emitted as part of a stream (e.g., chunk, embedding, relation).
class MemoryTaskOutput<T> extends MemoryTaskEvent {
  MemoryTaskOutput({required this.value, super.timestamp});

  final T value;
}

/// Allows a task to propagate updated context downstream.
class MemoryTaskContextUpdate extends MemoryTaskEvent {
  MemoryTaskContextUpdate({required this.context, super.timestamp});

  final MemoryTaskContext context;
}

/// Error emitted when a recoverable failure occurs inside a task.
class MemoryTaskError extends MemoryTaskEvent {
  MemoryTaskError({required this.error, this.stackTrace, super.timestamp});

  final Object error;
  final StackTrace? stackTrace;
}

/// Signature every task must implement.
abstract class MemoryTask {
  MemoryTask({required this.name, this.description});

  /// Human-readable identifier for the task.
  final String name;

  /// Optional description for documentation and telemetry.
  final String? description;

  /// Executes the task and streams events back to the pipeline.
  Stream<MemoryTaskEvent> run(MemoryTaskContext context);
}

/// Base class for tasks that input raw content and output structured data.
abstract class MemoryTaskWithInput<TInput, TOutput> extends MemoryTask {
  MemoryTaskWithInput({required super.name, super.description});

  /// Processes the input and returns output.
  Future<TOutput> process(TInput input, MemoryTaskContext context);
}

/// Task that captures raw text content from various sources.
class CaptureTask extends MemoryTask {
  CaptureTask({this.source = 'manual'})
      : super(name: 'capture', description: 'Capture content from source');

  final String source;

  @override
  Stream<MemoryTaskEvent> run(MemoryTaskContext context) async* {
    yield MemoryTaskLog(
      level: 'info',
      message: 'Starting content capture from $source',
    );

    // Simulate capturing content based on source
    final content = switch (source) {
      'manual' =>
        context.metadata['content'] as String? ?? 'Sample content to process',
      'clipboard' =>
        'Content from clipboard', // TODO: Implement actual clipboard access
      'voice' =>
        'Transcribed voice content', // TODO: Implement voice transcription
      _ => 'Unknown source content',
    };

    yield MemoryTaskOutput<Map<String, Object?>>(
      value: {
        'content': content,
        'source': source,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    yield MemoryTaskLog(
      level: 'info',
      message: 'Content captured successfully',
    );
  }
}

/// Task that chunks content into processable segments.
class ChunkTask extends MemoryTask {
  ChunkTask({this.maxChunkSize = 512})
      : super(name: 'chunk', description: 'Chunk content into segments');

  final int maxChunkSize;

  @override
  Stream<MemoryTaskEvent> run(MemoryTaskContext context) async* {
    yield MemoryTaskLog(level: 'info', message: 'Starting content chunking');

    // Get content from context (could be from previous task output)
    final content = context.metadata['content'] as String? ?? '';

    if (content.isEmpty) {
      yield MemoryTaskError(error: ArgumentError('No content to chunk'));
      return;
    }

    // Simple chunking by sentences and size
    final sentences = content.split(RegExp(r'[.!?]+'));
    final chunks = <String>[];

    String currentChunk = '';
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;

      if (currentChunk.length + trimmed.length > maxChunkSize &&
          currentChunk.isNotEmpty) {
        chunks.add(currentChunk.trim());
        currentChunk = trimmed;
      } else {
        if (currentChunk.isNotEmpty) currentChunk += '. ';
        currentChunk += trimmed;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    for (int i = 0; i < chunks.length; i++) {
      yield MemoryTaskOutput<Map<String, Object?>>(
        value: {
          'chunk': chunks[i],
          'index': i,
          'total': chunks.length,
          'source': context.metadata['source'] ?? 'unknown',
        },
      );
    }

    yield MemoryTaskLog(
      level: 'info',
      message: 'Chunked content into ${chunks.length} segments',
    );
  }
}

/// Task that generates embeddings for content chunks.
class EmbedTask extends MemoryTask {
  EmbedTask({required this.adapter})
      : super(name: 'embed', description: 'Generate embeddings for chunks');

  final EmbeddingsAdapter adapter;

  @override
  Stream<MemoryTaskEvent> run(MemoryTaskContext context) async* {
    yield MemoryTaskLog(
      level: 'info',
      message: 'Starting embedding generation',
    );

    final chunk = context.metadata['chunk'] as String?;
    if (chunk == null || chunk.isEmpty) {
      yield MemoryTaskError(error: ArgumentError('No chunk to embed'));
      return;
    }

    try {
      final embedding = await adapter.embed(chunk);

      yield MemoryTaskOutput<Map<String, Object?>>(
        value: {
          'chunk': chunk,
          'embedding': embedding,
          'dimension': embedding.length,
          'provider': adapter.providerName,
          'index': context.metadata['index'] ?? 0,
        },
      );

      yield MemoryTaskLog(
        level: 'info',
        message: 'Generated ${embedding.length}D embedding',
      );
    } catch (e) {
      yield MemoryTaskError(error: e);
    }
  }
}

/// Task that loads embeddings and content into the memory graph.
class LoadTask extends MemoryTask {
  LoadTask({required this.memoryGraph})
      : super(name: 'load', description: 'Load embeddings into memory graph');

  final MemoryGraph memoryGraph;

  @override
  Stream<MemoryTaskEvent> run(MemoryTaskContext context) async* {
    yield MemoryTaskLog(
      level: 'info',
      message: 'Starting memory graph loading',
    );

    final chunk = context.metadata['chunk'] as String?;
    final embedding = context.metadata['embedding'] as List<double>?;

    if (chunk == null || embedding == null) {
      yield MemoryTaskError(
        error: ArgumentError('Missing chunk or embedding data'),
      );
      return;
    }

    try {
      final memoryEmbedding = MemoryEmbedding(
        vector: embedding,
        provider: context.metadata['provider'] as String? ?? 'unknown',
        dimension: embedding.length,
      );

      final node = MemoryNode(
        content: chunk,
        type: 'chunk',
        embedding: memoryEmbedding,
        metadata: {
          'source': context.metadata['source'] ?? 'unknown',
          'index': context.metadata['index'] ?? 0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'namespace': context.datasetId ?? 'default',
        },
      );

      final nodeId = await memoryGraph.storeNode(node);

      yield MemoryTaskOutput<Map<String, Object?>>(
        value: {
          'nodeId': nodeId,
          'chunk': chunk,
          'namespace': context.datasetId ?? 'default',
        },
      );

      yield MemoryTaskLog(
        level: 'info',
        message: 'Loaded node $nodeId into memory graph',
      );
    } catch (e) {
      yield MemoryTaskError(error: e);
    }
  }
}
