import 'dart:async';
import 'dart:io';

import 'package:onnxruntime/onnxruntime.dart';

import 'on_device_embedding_backend.dart';
import 'onnx_text_embedding_runner.dart';

/// Creates an [OrtSession] on demand (e.g., from file path).
typedef OnnxSessionFactory = Future<OrtSession> Function();

/// Runs inference with a prepared [OrtSession].
typedef OnnxEmbeddingRunner =
    Future<List<double>> Function(OrtSession session, String text);

class OnnxEmbeddingBackend implements OnDeviceEmbeddingBackend {
  OnnxEmbeddingBackend({
    required this.sessionFactory,
    required this.runner,
    this.modelId = 'onnx-model',
  });

  factory OnnxEmbeddingBackend.file({
    required String modelPath,
    required OnnxTextEmbeddingRunner embeddingRunner,
    String modelId = 'onnx-text-embedding',
  }) {
    return OnnxEmbeddingBackend(
      sessionFactory: () async {
        final sessionOptions = OrtSessionOptions();
        return OrtSession.fromFile(File(modelPath), sessionOptions);
      },
      runner: embeddingRunner.infer,
      modelId: modelId,
    );
  }

  final OnnxSessionFactory sessionFactory;
  final OnnxEmbeddingRunner runner;

  @override
  final String modelId;

  OrtSession? _session;
  int? _dimension;

  @override
  String get runtime => 'onnx';

  @override
  int? get dimension => _dimension;

  @override
  bool get isLoaded => _session != null;

  @override
  Future<void> load() async {
    if (_session != null) {
      return;
    }
    _session = await sessionFactory();
  }

  @override
  Future<List<double>> infer(String text) async {
    final session = _session;
    if (session == null) {
      throw StateError('OnnxEmbeddingBackend.load must be called before infer');
    }
    final output = await runner(session, text);
    _dimension ??= output.length;
    return output;
  }

  @override
  Future<void> dispose() async {
    final session = _session;
    _session = null;
    session?.release();
  }
}
