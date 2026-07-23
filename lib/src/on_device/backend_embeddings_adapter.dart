import 'dart:async';
import 'package:isar_agent_memory/src/embeddings_adapter.dart';
import 'package:isar_agent_memory/src/embedding_telemetry.dart';
import 'on_device_embedding_backend.dart';

/// Adapts any [OnDeviceEmbeddingBackend] (Hash, TFLite, ONNX, Resilient)
/// to the standard [EmbeddingsAdapter] interface.
///
/// This allows Pocket Cerebro-style backends to be used wherever an
/// [EmbeddingsAdapter] is expected (e.g., in [MemoryGraph]).
///
/// Example:
/// ```dart
/// final adapter = BackendEmbeddingsAdapter(
///   backend: HashEmbeddingBackend(dimension: 256),
/// );
/// final graph = MemoryGraph(isar, embeddingsAdapter: adapter);
/// ```
class BackendEmbeddingsAdapter implements EmbeddingsAdapter {
  final OnDeviceEmbeddingBackend backend;
  final EmbeddingTelemetryRecorder? telemetry;
  bool _loaded = false;

  BackendEmbeddingsAdapter({
    required this.backend,
    this.telemetry,
  });

  @override
  String get providerName => 'backend:${backend.runtime}';

  @override
  int get dimension => backend.dimension ?? 0;

  /// Ensure the backend is loaded before first use.
  Future<void> ensureLoaded() async {
    if (!_loaded) {
      await backend.load();
      _loaded = true;
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    await ensureLoaded();
    final stopwatch = Stopwatch()..start();
    try {
      final vector = await backend.infer(text);
      telemetry?.record(EmbeddingTelemetrySample(
        runtime: backend.runtime,
        modelId: backend.modelId,
        latency: stopwatch.elapsed,
        dimension: vector.length,
        success: true,
      ));
      return vector;
    } catch (e) {
      telemetry?.record(EmbeddingTelemetrySample(
        runtime: backend.runtime,
        modelId: backend.modelId,
        latency: stopwatch.elapsed,
        dimension: 0,
        success: false,
      ));
      rethrow;
    }
  }

  /// Release backend resources.
  Future<void> dispose() async {
    await backend.dispose();
    _loaded = false;
  }
}
