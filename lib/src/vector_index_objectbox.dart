import 'dart:math' as math;
import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';
import '../objectbox.g.dart';
import 'vector_index.dart';

/// Interface for ObjectBox vector entities to allow generic indexing logic.
abstract class ObxVectorEntity {
  int get id;
  set id(int value);
  String get docKey;
  String? get content;
  List<double>? get vector;
}

/// ObjectBox entity to store vectors with an HNSW index (768 dims).
@Entity()
class ObxVectorDoc implements ObxVectorEntity {
  @Id()
  @override
  int id = 0;

  @Unique()
  @override
  String docKey;

  @override
  String? content;

  @HnswIndex(dimensions: 768, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  @override
  List<double>? vector;

  ObxVectorDoc({required this.docKey, this.content, this.vector});
}

/// ObjectBox entity to store vectors with an HNSW index (384 dims).
@Entity()
class ObxVectorDoc384 implements ObxVectorEntity {
  @Id()
  @override
  int id = 0;

  @Unique()
  @override
  String docKey;

  @override
  String? content;

  @HnswIndex(dimensions: 384, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  @override
  List<double>? vector;

  ObxVectorDoc384({required this.docKey, this.content, this.vector});
}

abstract class ObjectBoxVectorIndex implements VectorIndex {
  /// Convenience: open a Store internally and create an index.
  /// Consumers don't need to import generated code.
  static ObjectBoxVectorIndex open({
    String? directory,
    String namespace = 'default',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
    int dimension = 768,
  }) {
    final store = openStore(directory: directory);
    return ObjectBoxVectorIndex(
      store: store,
      namespace: namespace,
      normalize: normalize,
      metric: metric,
      dimension: dimension,
    );
  }

  factory ObjectBoxVectorIndex({
    required Store store,
    String namespace = 'default',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
    int dimension = 768,
  }) {
    if (dimension == 384) {
      return _ObjectBoxVectorIndex384(
        store: store,
        namespace: namespace,
        normalize: normalize,
        metric: metric,
      );
    } else if (dimension == 768) {
      return _ObjectBoxVectorIndex768(
        store: store,
        namespace: namespace,
        normalize: normalize,
        metric: metric,
      );
    } else {
      throw ArgumentError(
          'ObjectBoxVectorIndex currently only supports dimensions 384 and 768. '
          'Requested: $dimension. You may need to add a new entity and update the factory.');
    }
  }
}

abstract class _BaseObjectBoxVectorIndex<T extends ObxVectorEntity>
    implements ObjectBoxVectorIndex {
  final String _namespace;
  final bool _normalize;
  final VectorMetric _metric;
  final Store _store;
  final int _dimension;
  late final Box<T> _box;

  _BaseObjectBoxVectorIndex({
    required Store store,
    required int dimension,
    String namespace = 'default',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
  })  : _store = store,
        _dimension = dimension,
        _namespace = namespace,
        _normalize = normalize,
        _metric = metric {
    _box = Box<T>(_store);
  }

  @override
  String get provider => 'objectbox';

  @override
  int get dimension => _dimension;

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

  /// Returns the query property for docKey.
  QueryStringProperty<T> get _docKeyProperty;

  /// Returns the query property for the vector.
  QueryHnswProperty<T> get _vectorProperty;

  /// Factory to create a new entity instance.
  T _createEntity(String key, String content, List<double> vector);

  @override
  Future<void> addDocument(
      String id, String content, Float32List vector) async {
    // Check dimension
    if (vector.length != _dimension) {
      throw ArgumentError(
        'ObjectBoxVectorIndex($_dimension) requires vectors of dimension $_dimension. '
        'Received ${vector.length}.',
      );
    }

    var vec = vector;
    if (_metric == VectorMetric.cosine && _normalize) {
      vec = _normalizeVec(vec);
    }

    final key = _key(id);
    // Upsert by unique docKey
    final existing =
        _box.query(_docKeyProperty.equals(key)).build().findFirst();
    final entity = _createEntity(key, content, vec.toList(growable: false));
    if (existing != null) {
      entity.id = existing.id;
    }
    _box.put(entity, mode: PutMode.put);
  }

  @override
  Future<void> removeDocument(String id) async {
    final key = _key(id);
    final qb = _box.query(_docKeyProperty.equals(key)).build();
    final found = qb.findFirst();
    qb.close();
    if (found != null) {
      _box.remove(found.id);
    }
  }

  @override
  Future<List<VectorSearchResult>> search(Float32List query,
      {int topK = 5}) async {
    if (query.length != _dimension) {
      throw ArgumentError(
        'ObjectBoxVectorIndex($_dimension) requires query vectors of dimension $_dimension. '
        'Received ${query.length}.',
      );
    }

    var q = query;
    if (_metric == VectorMetric.cosine && _normalize) {
      q = _normalizeVec(q);
    }

    final qb = _box
        .query(_vectorProperty.nearestNeighborsF32(
            q.toList(growable: false), topK))
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

class _ObjectBoxVectorIndex768 extends _BaseObjectBoxVectorIndex<ObxVectorDoc> {
  _ObjectBoxVectorIndex768({
    required super.store,
    super.namespace,
    super.normalize,
    super.metric,
  }) : super(dimension: 768);

  @override
  QueryStringProperty<ObxVectorDoc> get _docKeyProperty => ObxVectorDoc_.docKey;

  @override
  QueryHnswProperty<ObxVectorDoc> get _vectorProperty => ObxVectorDoc_.vector;

  @override
  ObxVectorDoc _createEntity(String key, String content, List<double> vector) {
    return ObxVectorDoc(docKey: key, content: content, vector: vector);
  }
}

class _ObjectBoxVectorIndex384
    extends _BaseObjectBoxVectorIndex<ObxVectorDoc384> {
  _ObjectBoxVectorIndex384({
    required super.store,
    super.namespace,
    super.normalize,
    super.metric,
  }) : super(dimension: 384);

  @override
  QueryStringProperty<ObxVectorDoc384> get _docKeyProperty =>
      ObxVectorDoc384_.docKey;

  @override
  QueryHnswProperty<ObxVectorDoc384> get _vectorProperty =>
      ObxVectorDoc384_.vector;

  @override
  ObxVectorDoc384 _createEntity(
      String key, String content, List<double> vector) {
    return ObxVectorDoc384(docKey: key, content: content, vector: vector);
  }
}
