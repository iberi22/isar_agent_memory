import 'package:isar/isar.dart';

part 'degree.g.dart';

/// Tracks recency, frequency, and importance (activation) for a MemoryNode or Edge.
@embedded
class Degree {
  /// Number of times the node/edge has been accessed or reinforced.
  int frequency;

  /// Last access timestamp.
  DateTime? lastAccessed;

  /// Importance score (customizable by agent).
  double importance;

  /// Optional metadata (e.g., agent, session, tags).
  @ignore
  Map<String, dynamic>? metadata;

  Degree({
    this.frequency = 1,
    this.lastAccessed,
    this.importance = 1.0,
    this.metadata,
  });
}
