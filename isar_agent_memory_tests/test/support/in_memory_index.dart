import 'dart:typed_data';
import 'dart:math' as math;
import 'package:isar_agent_memory/isar_agent_memory.dart';

/// Simple in-memory VectorIndex for tests. Avoids native libs/plugins.
class InMemoryVectorIndex implements VectorIndex {
  final String _namespace;
  final bool _normalize;
  final VectorMetric _metric;
  final Map<String, Float32List> _store = {};

  InMemoryVectorIndex({
    String namespace = 'test',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
  })  : _namespace = namespace,
        _normalize = normalize,
        _metric = metric;

  @override
  String get provider => 'in-memory';
  @override
  String get namespace => _namespace;
  @override
  bool get normalize => _normalize;
  @override
  VectorMetric get metric => _metric;

  @override
  Future<void> addDocument(
    String id,
    String content,
    Float32List vector,
  ) async {
    // Optionally store normalized vectors for cosine metric
    if (_metric == VectorMetric.cosine && _normalize) {
      _store[id] = _normalized(vector);
    } else {
      _store[id] = vector;
    }
  }

  @override
  Future<void> removeDocument(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<VectorSearchResult>> search(
    Float32List query, {
    int topK = 5,
  }) async {
    if (_store.isEmpty) return [];
    final scores = <String, double>{};

    final q = (_metric == VectorMetric.cosine && _normalize)
        ? _normalized(query)
        : query;

    for (final entry in _store.entries) {
      final id = entry.key;
      final vec = entry.value;
      final s = _similarity(q, vec);
      scores[id] = s;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(topK)
        .map((e) => VectorSearchResult(id: e.key, score: e.value))
        .toList();
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<void> load() async {}

  // --- Helpers ---
  double _dot(Float32List a, Float32List b) {
    final len = (a.length < b.length) ? a.length : b.length;
    var s = 0.0;
    for (var i = 0; i < len; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  double _norm(Float32List v) {
    var s = 0.0;
    for (var i = 0; i < v.length; i++) {
      s += v[i] * v[i];
    }
    return s == 0.0 ? 0.0 : math.sqrt(s);
  }

  Float32List _normalized(Float32List v) {
    final n = _norm(v);
    if (n == 0.0) return v;
    final out = Float32List(v.length);
    for (var i = 0; i < v.length; i++) {
      out[i] = v[i] / n;
    }
    return out;
  }

  double _similarity(Float32List q, Float32List v) {
    switch (_metric) {
      case VectorMetric.cosine:
        if (_normalize) {
          // dot of two normalized vectors is cosine
          return _dot(q, v);
        } else {
          final denom = _norm(q) * _norm(v);
          if (denom == 0.0) return -1.0;
          return _dot(q, v) / denom;
        }
      case VectorMetric.l2:
        // Use negative squared L2 distance so that higher is better
        final len = (q.length < v.length) ? q.length : v.length;
        var d2 = 0.0;
        for (var i = 0; i < len; i++) {
          final diff = q[i] - v[i];
          d2 += diff * diff;
        }
        return -d2;
      case VectorMetric.dot:
        return _dot(q, v);
    }
  }
}
