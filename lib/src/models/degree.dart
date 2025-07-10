import 'package:isar/isar.dart';

part 'degree.g.dart';

/// Tracks recency, frequency, and importance for a `MemoryNode` or `MemoryEdge`.
///
/// This class provides a mechanism to score the relevance of a piece of memory,
/// which is crucial for memory retrieval and management in cognitive architectures.
@embedded
class Degree {
  /// Creates a new instance of [Degree].
  ///
  /// [frequency] defaults to 1 and [importance] defaults to 1.0.
  Degree({
    this.frequency = 1,
    this.lastAccessed,
    this.importance = 1.0,
    this.metadata,
  });

  /// The number of times the node or edge has been accessed or reinforced.
  ///
  /// A higher frequency suggests greater relevance.
  int frequency;

  /// The timestamp of the last time the node or edge was accessed.
  ///
  /// Used to calculate recency.
  DateTime? lastAccessed;

  /// A score representing the intrinsic importance of the node or edge.
  ///
  /// This can be set manually or adjusted by the agent's logic.
  double importance;

  /// Arbitrary extensible metadata.
  ///
  /// A map for storing additional, non-indexed data. This field is ignored by
  /// Isar and is not persisted in the database.
  @ignore
  Map<String, dynamic>? metadata;
}
