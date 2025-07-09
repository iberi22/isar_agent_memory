import 'package:isar/isar.dart';

part 'memory_edge.g.dart';

/// Represents a directed relationship between two MemoryNodes in the memory graph.
@collection
class MemoryEdge {
  Id id = Isar.autoIncrement;

  /// Source node ID.
  late int fromNodeId;

  /// Target node ID.
  late int toNodeId;

  /// Relationship type (e.g., 'cause', 'context', 'response', 'similarity', etc.)
  late String relation;

  /// Optional weight/strength of the relationship (for activation, recency, etc.)
  double? weight;

  /// ISO8601 timestamp of creation.
  late DateTime createdAt;

  /// Optional metadata.
  @ignore
  Map<String, dynamic>? metadata;

  MemoryEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.relation,
    this.weight,
    this.metadata,
  }) : createdAt = DateTime.now();
}
