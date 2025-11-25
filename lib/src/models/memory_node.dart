import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'memory_embedding.dart';
import 'degree.dart';

part 'memory_node.g.dart';

/// Represents a memory, fact, message, or concept in the universal agent memory graph.
///
/// Each [MemoryNode] is a fundamental unit of information, analogous to a concept
/// or a piece of data in a cognitive architecture. It can be a raw piece of text,
/// a user message, a processed fact, or any other element of knowledge.
@collection
@JsonSerializable(explicitToJson: true)
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
    this.version,
    this.deviceId,
    this.isDeleted = false,
    this.modifiedAt,
    this.layer = 0,
    this.uuid,
  }) : createdAt = DateTime.now() {
    this.degree = degree ?? Degree();
    if (modifiedAt == null) {
      modifiedAt = DateTime.now();
    }
    if (uuid == null) {
      uuid = const Uuid().v4();
    }
  }

  /// Unique identifier for this node, managed by Isar.
  /// Isar automatically identifies 'id' field as the ID.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Id id = Isar.autoIncrement;

  /// Globally unique identifier for synchronization.
  /// Indexed for fast lookups during sync.
  @Index(unique: true, replace: true)
  String? uuid;

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

  /// The timestamp of the last update or access (business logic update).
  ///
  /// Can be used to track recency and relevance.
  DateTime? updatedAt;

  /// The timestamp when this record was last modified (system-level sync).
  ///
  /// Used for Last-Write-Wins (LWW) conflict resolution.
  DateTime? modifiedAt;

  /// Version identifier (e.g., hash or monotonic counter) for synchronization.
  String? version;

  /// ID of the device that last modified this record.
  String? deviceId;

  /// Soft delete flag (tombstone) for synchronization.
  bool isDeleted;

  /// HiRAG: The hierarchical layer this node belongs to.
  /// 0 = base layer (raw text/facts).
  /// >0 = summary/abstract layers.
  int layer;

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
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic>? metadata;

  // JSON serialization helpers
  factory MemoryNode.fromJson(Map<String, dynamic> json) => _$MemoryNodeFromJson(json);
  Map<String, dynamic> toJson() => _$MemoryNodeToJson(this);
}
