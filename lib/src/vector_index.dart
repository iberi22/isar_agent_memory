import 'dart:typed_data';

/// Result returned by a vector index search.
class VectorSearchResult {
  final String id;
  final double
      score; // Smaller is better for distance; larger is better for similarity depending on metric
  const VectorSearchResult({required this.id, required this.score});
}

/// Metric used for vector similarity.
enum VectorMetric {
  cosine,
  l2,
  dot,
}

/// Abstraction for a vector index backend.
abstract class VectorIndex {
  /// Human-readable name of the backend (e.g., 'objectbox').
  String get provider;

  /// Namespace allows having multiple indices (e.g., by embedding provider + dimension).
  String get namespace;

  /// Configure whether vectors are normalized on write/search (useful for cosine).
  bool get normalize;

  /// Metric used by this index.
  VectorMetric get metric;

  /// Adds or replaces a document vector in the index.
  Future<void> addDocument(String id, String content, Float32List vector);

  /// Removes a document from the index.
  Future<void> removeDocument(String id);

  /// Searches the index and returns up to [topK] results.
  Future<List<VectorSearchResult>> search(Float32List query, {int topK = 5});

  /// Clears the index (testing/maintenance).
  Future<void> clear();

  /// Loads persisted state into memory (if applicable).
  Future<void> load();
}
