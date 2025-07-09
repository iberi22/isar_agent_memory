import 'package:isar/isar.dart';

part 'memory_embedding.g.dart';

/// Represents a semantic embedding vector for a MemoryNode.
@embedded
class MemoryEmbedding {
  /// The embedding vector (float list).
  late List<double> vector;

  /// Optional provider/model info (e.g., 'openai', 'gemini', 'local', etc.)
  String? provider;

  /// Optional dimensionality.
  int? dimension;

  /// ISO8601 timestamp of creation.
  late DateTime createdAt;

  MemoryEmbedding({
    this.vector = const [],
    this.provider,
    this.dimension,
  }) : createdAt = DateTime.now();
}
