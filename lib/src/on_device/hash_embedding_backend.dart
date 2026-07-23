import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'on_device_embedding_backend.dart';

/// Lightweight deterministic backend that synthesizes embeddings from text hashes.
/// Useful for development, testing, or as a fallback when native runtimes are
/// not yet available on device.
class HashEmbeddingBackend implements OnDeviceEmbeddingBackend {
  HashEmbeddingBackend({
    int dimension = 256,
    this.modelId = 'hash-embeddings-v1',
    this.runtime = 'hash',
  }) : assert(dimension > 0, 'dimension must be positive'),
       _dimension = dimension,
       _buffer = Float32List(dimension);

  final int _dimension;

  @override
  final String modelId;

  @override
  final String runtime;

  final Float32List _buffer;

  @override
  int? get dimension => _dimension;

  @override
  bool get isLoaded => true;

  @override
  Future<void> load() async {}

  @override
  Future<List<double>> infer(String text) async {
    _buffer.fillRange(0, _buffer.length, 0);

    final runes = text.runes.toList();
    if (runes.isEmpty) {
      return _buffer.toList(growable: false);
    }

    for (var i = 0; i < runes.length; i++) {
      final code = runes[i];
      final idx = i % _buffer.length;
      final value = math.sin(code + idx) + math.cos(code * (idx + 1));
      _buffer[idx] += value;
    }

    return _buffer.toList(growable: false);
  }

  @override
  Future<void> dispose() async {}
}
