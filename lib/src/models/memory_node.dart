import 'package:isar/isar.dart';
import 'memory_embedding.dart';
import 'degree.dart';

part 'memory_node.g.dart';

/// Represents a memory, fact, message, or concept in the universal agent memory graph.
@collection
class MemoryNode {
  /// Unique identifier for this node.
  Id id = Isar.autoIncrement;

  /// The main textual content or value of the memory.
  late String content;

  /// Optional type/classification (e.g., 'fact', 'message', 'goal', etc.)
  String? type;

  /// ISO8601 timestamp of creation.
  late DateTime createdAt;

  /// ISO8601 timestamp of last update or access.
  DateTime? updatedAt;

  /// Embedding vector (semantic representation).
  MemoryEmbedding? embedding;

  /// Activation/degree info: recency, frequency, importance.
  Degree? degree;

  /// Arbitrary extensible metadata (tags, user, session, etc.)
  @ignore
  Map<String, dynamic>? metadata;

  MemoryNode({
    required this.content,
    this.type,
    this.updatedAt,
    this.embedding,
    Degree? degree,
    this.metadata,
  })  : createdAt = DateTime.now(),
        this.degree = degree ?? Degree();
}
