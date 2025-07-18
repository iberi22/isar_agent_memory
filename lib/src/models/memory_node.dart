import 'package:isar/isar.dart';
import 'memory_embedding.dart';
import 'degree.dart';

part 'memory_node.g.dart';

/// Represents a memory, fact, message, or concept in the universal agent memory graph.
///
/// Each [MemoryNode] is a fundamental unit of information, analogous to a concept
/// or a piece of data in a cognitive architecture. It can be a raw piece of text,
/// a user message, a processed fact, or any other element of knowledge.
@collection
class MemoryNode {
  /// Creates a new instance of a [MemoryNode].
  ///
  /// [content] is the only required parameter.
  /// [degree] is initialized to a default [Degree] object if not provided.
  MemoryNode({
    required this.content,
    this.type,
    this.updatedAt,
    this.embedding,
    Degree? degree,
    this.metadata,
  })  : createdAt = DateTime.now() {
    this.degree = degree ?? Degree();
  }

  /// Unique identifier for this node, managed by Isar.
  Id id = Isar.autoIncrement;

  /// The main textual content or value of the memory.
  ///
  /// This is the core data that the node represents.
  late String content;

  /// Optional type or classification for the node (e.g., 'fact', 'message', 'goal').
  ///
  /// This helps in categorizing and querying different types of memories.
  String? type;

  /// The timestamp when this memory node was created.
  ///
  /// Automatically set to the current time upon creation.
  late DateTime createdAt;

  /// The timestamp of the last update or access.
  ///
  /// Can be used to track recency and relevance.
  DateTime? updatedAt;

  /// The embedding vector representing the semantic meaning of the [content].
  ///
  /// This is used for semantic search and similarity comparisons.
  MemoryEmbedding? embedding;

  /// Contains activation scores like recency, frequency, and importance.
  ///
  /// The [Degree] object helps in determining the relevance of this node over time.
  Degree? degree;

  /// Arbitrary extensible metadata.
  ///
  /// A map for storing additional, non-indexed data such as tags, user IDs,
  /// or session information. This field is ignored by Isar and is not persisted
  /// in the database directly.
  @ignore
  Map<String, dynamic>? metadata;
}
