import 'dart:async';
import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'on_device_embedding_backend.dart';
import 'tflite_text_embedding_runner.dart';

/// Signature responsible for running inference using a loaded [Interpreter].
typedef TFLiteEmbeddingRunner = Future<List<double>> Function(
    Interpreter interpreter, String text);

/// On-device embedding backend backed by TensorFlow Lite.
class TFLiteEmbeddingBackend implements OnDeviceEmbeddingBackend {
  TFLiteEmbeddingBackend({
    required this.modelPath,
    required this.runner,
    InterpreterOptions? options,
    this.modelId = 'tflite-model',
    this.isAsset = false,
  }) : _options = options ?? InterpreterOptions();

  factory TFLiteEmbeddingBackend.file({
    required String modelPath,
    required TFLiteTextEmbeddingConfig config,
    InterpreterOptions? options,
    String modelId = 'tflite-text-embedding',
  }) {
    final runner = TFLiteTextEmbeddingRunner(config);
    return TFLiteEmbeddingBackend(
      modelPath: modelPath,
      runner: runner.infer,
      options: options,
      modelId: modelId,
      isAsset: false,
    );
  }

  /// Path to the TFLite model. If [isAsset] is true the model is loaded from Flutter assets.
  final String modelPath;

  /// Whether [modelPath] points to an asset bundled with the Flutter app.
  final bool isAsset;

  /// Human-readable model identifier (used in telemetry and provider name).
  @override
  final String modelId;

  final InterpreterOptions _options;
  final TFLiteEmbeddingRunner runner;

  Interpreter? _interpreter;
  int? _dimension;

  @override
  String get runtime => 'tflite';

  @override
  int? get dimension => _dimension;

  @override
  bool get isLoaded => _interpreter != null;

  @override
  Future<void> load() async {
    if (_interpreter != null) {
      return;
    }
    if (isAsset) {
      _interpreter = await Interpreter.fromAsset(modelPath, options: _options);
    } else {
      _interpreter = Interpreter.fromFile(File(modelPath), options: _options);
    }
  }

  @override
  Future<List<double>> infer(String text) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError(
        'TFLiteEmbeddingBackend.load must be called before infer',
      );
    }
    final output = await runner(interpreter, text);
    _dimension ??= output.length;
    return output;
  }

  @override
  Future<void> dispose() async {
    final interpreter = _interpreter;
    _interpreter = null;
    interpreter?.close();
  }
}
