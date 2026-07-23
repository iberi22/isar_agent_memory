import 'dart:async';

import 'on_device_embedding_backend.dart';

/// Wraps a primary on-device backend with a fallback strategy. Attempts to load
/// and use [primary] first, falling back to [fallback] when loading or
/// inference fails. Helpful for environments (e.g., CI, desktop tests) where
/// native runtimes such as TFLite may be unavailable.
class ResilientEmbeddingBackend implements OnDeviceEmbeddingBackend {
  ResilientEmbeddingBackend({
    required this.primary,
    required this.fallback,
    this.onFallback,
  });

  final OnDeviceEmbeddingBackend primary;
  final OnDeviceEmbeddingBackend fallback;
  final void Function(Object error, StackTrace stack)? onFallback;

  OnDeviceEmbeddingBackend? _active;
  bool _primaryFailed = false;

  OnDeviceEmbeddingBackend get _backend =>
      _active ?? (_primaryFailed ? fallback : primary);

  @override
  String get runtime => _backend.runtime;

  @override
  String get modelId => _backend.modelId;

  @override
  int? get dimension =>
      _backend.dimension ??
      (_primaryFailed ? fallback.dimension : primary.dimension);

  @override
  bool get isLoaded => _backend.isLoaded;

  @override
  Future<void> load() async {
    if (_active != null && _active!.isLoaded) {
      return;
    }

    if (!_primaryFailed) {
      try {
        await primary.load();
        _active = primary;
        return;
      } catch (error, stack) {
        _primaryFailed = true;
        onFallback?.call(error, stack);
        print(
          'ResilientEmbeddingBackend: primary backend failed to load. '
          'Falling back to ${fallback.runtime}:${fallback.modelId}. Error: $error',
        );
      }
    }

    await fallback.load();
    _active = fallback;
  }

  @override
  Future<List<double>> infer(String text) async {
    try {
      await load();
      return await _backend.infer(text);
    } catch (error, stack) {
      if (!_primaryFailed && _backend == primary) {
        _primaryFailed = true;
        onFallback?.call(error, stack);
        print(
          'ResilientEmbeddingBackend: primary backend failed during infer. '
          'Switching to fallback ${fallback.runtime}:${fallback.modelId}. '
          'Error: $error',
        );
        await fallback.load();
        _active = fallback;
        return fallback.infer(text);
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await primary.dispose();
    await fallback.dispose();
    _active = null;
  }
}
