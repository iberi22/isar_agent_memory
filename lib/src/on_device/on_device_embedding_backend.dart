import 'dart:async';

/// Contract for on-device embedding backends (TFLite, ONNX Runtime, CoreML).
abstract class OnDeviceEmbeddingBackend {
  /// Human readable backend identifier (e.g., `tflite`, `onnx`, `coreml`).
  String get runtime;

  /// Identifier for the loaded model (e.g., `text-embedding-004-int8`).
  String get modelId;

  /// Expected embedding dimension once the backend is ready.
  /// Implementations may return `null` until the model is loaded.
  int? get dimension;

  /// Whether the backend has completed model initialization.
  bool get isLoaded;

  /// Performs any heavy initialization (model loading, delegate setup).
  Future<void> load();

  /// Generates an embedding for the provided [text].
  Future<List<double>> infer(String text);

  /// Releases native resources.
  Future<void> dispose();
}
