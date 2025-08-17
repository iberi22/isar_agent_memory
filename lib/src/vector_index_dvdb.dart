import 'dart:typed_data';
import 'vector_index.dart';

@Deprecated('DVDB backend has been removed. Use ObjectBoxVectorIndex instead.')
class DvdbVectorIndex implements VectorIndex {
  DvdbVectorIndex({required String namespace, bool normalize = true, VectorMetric metric = VectorMetric.cosine});

  Never _unsupported() => throw UnsupportedError('DVDB backend has been removed from this package.');

  @override
  String get provider => 'dvdb';
  @override
  String get namespace => _unsupported();
  @override
  bool get normalize => _unsupported();
  @override
  VectorMetric get metric => _unsupported();
  @override
  Future<void> addDocument(String id, String content, Float32List vector) async => _unsupported();
  @override
  Future<void> removeDocument(String id) async => _unsupported();
  @override
  Future<List<VectorSearchResult>> search(Float32List query, {int topK = 5}) async => _unsupported();
  @override
  Future<void> clear() async => _unsupported();
  @override
  Future<void> load() async => _unsupported();
}
