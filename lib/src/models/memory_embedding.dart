import 'package:isar/isar.dart';

part 'memory_embedding.g.dart';

/// Represents a semantic embedding vector for a `MemoryNode`.
///
/// This class stores the numerical representation of a node's content, which
/// is used for semantic search and similarity calculations.
@embedded
class MemoryEmbedding {
  /// Creates a new instance of [MemoryEmbedding].
  ///
  /// The [vector] defaults to an empty list.
  MemoryEmbedding({
    this.vector = const [],
    this.provider,
    this.dimension,
  }) : createdAt = DateTime.now();

  /// The list of floating-point numbers that constitutes the embedding vector.
  late List<double> vector;

  /// The provider or model that generated this embedding (e.g., 'openai', 'gemini').
  ///
  /// Useful for tracking the source of different embeddings.
  String? provider;

  /// The dimensionality of the embedding vector (i.e., the length of the [vector] list).
  int? dimension;

  /// The timestamp when this embedding was created.
  ///
  /// Automatically set to the current time upon creation.
  late DateTime createdAt;
}
