import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'memory_edge.g.dart';

/// Represents a directed relationship between two `MemoryNode`s in the memory graph.
///
/// Edges define how different pieces of information are connected, creating a
/// web of knowledge. The relationship is described by the [relation] property.
@collection
@JsonSerializable(explicitToJson: true)
class MemoryEdge {
  /// Creates a new instance of a [MemoryEdge].
  ///
  /// [fromNodeId], [toNodeId], and [relation] are required.
  MemoryEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.relation,
    this.weight,
    this.metadata,
    this.version,
    this.deviceId,
    this.isDeleted = false,
    this.modifiedAt,
    this.uuid,
  }) : createdAt = DateTime.now() {
    modifiedAt ??= DateTime.now();
    uuid ??= const Uuid().v4();
  }

  /// Unique identifier for this edge, managed by Isar.
  /// Isar automatically identifies 'id' field as the ID.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Id id = Isar.autoIncrement;

  /// Globally unique identifier for synchronization.
  /// Indexed for fast lookups during sync.
  @Index(unique: true, replace: true)
  String? uuid;

  /// The ID of the source node (the origin of the relationship).
  late int fromNodeId;

  /// The ID of the target node (the destination of the relationship).
  late int toNodeId;

  /// The type of relationship (e.g., 'cause', 'context', 'response', 'similarity').
  ///
  /// This label describes the nature of the connection between the two nodes.
  late String relation;

  /// An optional weight or strength of the relationship.
  ///
  /// This can be used for ranking, activation spreading, or determining the
  /// importance of a connection.
  double? weight;

  /// The timestamp when this edge was created.
  ///
  /// Automatically set to the current time upon creation.
  late DateTime createdAt;

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

  /// Arbitrary extensible metadata.
  ///
  /// A map for storing additional, non-indexed data. This field is ignored by
  /// Isar and is not persisted in the database.
  @ignore
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic>? metadata;

  // JSON serialization helpers
  factory MemoryEdge.fromJson(Map<String, dynamic> json) =>
      _$MemoryEdgeFromJson(json);
  Map<String, dynamic> toJson() => _$MemoryEdgeToJson(this);
}
