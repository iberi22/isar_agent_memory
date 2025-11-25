import 'dart:math' as math;
import 'dart:typed_data';
import 'package:objectbox/objectbox.dart'; // REQUIRED for annotations
// import '../objectbox.g.dart'; // Removing this temporarily to see if it fixes the cycle or if I need it for the Store class.
// Actually I need objectbox.g.dart for ObxVectorDoc_ and openStore.
import '../objectbox.g.dart';
import 'vector_index.dart';

/// ObjectBox entity to store vectors with an HNSW index.
/// NOTE: For now we fix the embedding dimension to 768 (Gemini text-embedding-004).
/// If you need a different dimension, create a separate entity and index.
@Entity()
class ObxVectorDoc {
  @Id()
  int id = 0;

  /// Namespaced ID (e.g., "default:123").
  @Unique()
  String docKey;

  String? content;

  /// Float vector with HNSW index. The dimension must match your embeddings.
  /// We default to 768 (Gemini text-embedding-004), but ObjectBox requires
  /// fixed dimensions at compile time. If you need 1536 (OpenAI), change this
  /// and regenerate code.
  @HnswIndex(dimensions: 768, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double>? vector;

  ObxVectorDoc({required this.docKey, this.content, this.vector});
}

class ObjectBoxVectorIndex implements VectorIndex {
  final String _namespace;
  final bool _normalize;
  final VectorMetric _metric;
  final Store _store;
  late final Box<ObxVectorDoc> _box;

  ObjectBoxVectorIndex({
    required Store store,
    String namespace = 'default',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
  })  : _store = store,
        _namespace = namespace,
        _normalize = normalize,
        _metric = metric {
    _box = Box<ObxVectorDoc>(_store);
  }

  /// Convenience: open a Store internally and create an index.
  /// Consumers don't need to import generated code.
  static ObjectBoxVectorIndex open({
    String? directory,
    String namespace = 'default',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
  }) {
    final store = openStore(directory: directory);
    return ObjectBoxVectorIndex(
      store: store,
      namespace: namespace,
      normalize: normalize,
      metric: metric,
    );
  }

  @override
  String get provider => 'objectbox';

  @override
  String get namespace => _namespace;

  @override
  bool get normalize => _normalize;

  @override
  VectorMetric get metric => _metric;

  Float32List _normalizeVec(Float32List v) {
    double sumSq = 0;
    for (final x in v) {
      sumSq += x * x;
    }
    if (sumSq == 0) return v;
    final scale = 1.0 / math.sqrt(sumSq);
    final out = Float32List(v.length);
    for (var i = 0; i < v.length; i++) {
      out[i] = v[i] * scale;
    }
    return out;
  }

  String _key(String id) => '$_namespace:$id';

  @override
  Future<void> addDocument(
      String id, String content, Float32List vector) async {
    // Check dimension
    if (vector.length != 768) {
      // Warning or throw? For now we throw to avoid crashes deep in ObjectBox
      // or silent failures.
      // Ideally, we should support multiple dimensions, but ObjectBox requires
      // fixed dimensions per @HnswIndex.
      throw ArgumentError(
        'ObjectBoxVectorIndex requires vectors of dimension 768. '
        'Received ${vector.length}. Change the @HnswIndex annotation and regenerate if needed.',
      );
    }

    var vec = vector;
    if (_metric == VectorMetric.cosine && _normalize) {
      vec = _normalizeVec(vec);
    }

    final key = _key(id);
    // Upsert by unique docKey
    final existing =
        _box.query(ObxVectorDoc_.docKey.equals(key)).build().findFirst();
    final entity = ObxVectorDoc(
      docKey: key,
      content: content,
      vector: vec.toList(growable: false),
    );
    if (existing != null) {
      entity.id = existing.id;
    }
    _box.put(entity, mode: PutMode.put);
  }

  @override
  Future<void> removeDocument(String id) async {
    final key = _key(id);
    final qb = _box.query(ObxVectorDoc_.docKey.equals(key)).build();
    final found = qb.findFirst();
    qb.close();
    if (found != null) {
      _box.remove(found.id);
    }
  }

  @override
  Future<List<VectorSearchResult>> search(Float32List query,
      {int topK = 5}) async {
    if (query.length != 768) {
       throw ArgumentError(
        'ObjectBoxVectorIndex requires query vectors of dimension 768. '
        'Received ${query.length}.',
      );
    }

    var q = query;
    if (_metric == VectorMetric.cosine && _normalize) {
      q = _normalizeVec(q);
    }

    final qb = _box
        .query(ObxVectorDoc_.vector
            .nearestNeighborsF32(q.toList(growable: false), topK))
        .build();
    try {
      final results = qb.findWithScores();
      return results
          .map((r) => VectorSearchResult(
                id: r.object.docKey.split(':').last,
                score: r.score,
              ))
          .toList(growable: false);
    } finally {
      qb.close();
    }
  }

  @override
  Future<void> clear() async {
    _box.removeAll();
  }

  @override
  Future<void> load() async {
    // ObjectBox is persisted automatically; nothing to load explicitly.
  }
}
