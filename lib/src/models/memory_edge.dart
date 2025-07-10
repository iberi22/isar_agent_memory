import 'package:isar/isar.dart';

part 'memory_edge.g.dart';

/// Represents a directed relationship between two `MemoryNode`s in the memory graph.
///
/// Edges define how different pieces of information are connected, creating a
/// web of knowledge. The relationship is described by the [relation] property.
@collection
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
  }) : createdAt = DateTime.now();

  /// Unique identifier for this edge, managed by Isar.
  Id id = Isar.autoIncrement;

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

  /// Arbitrary extensible metadata.
  ///
  /// A map for storing additional, non-indexed data. This field is ignored by
  /// Isar and is not persisted in the database.
  @ignore
  Map<String, dynamic>? metadata;
}
