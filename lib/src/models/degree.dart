import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'degree.g.dart';

/// Represents activation scores for a [MemoryNode].
///
/// This class tracks metrics that help determine the "temperature" or
/// relevance of a memory node, such as how recently it was accessed,
/// how often it is retrieved, and its intrinsic importance.
@embedded
@JsonSerializable()
class Degree {
  /// The timestamp of the last time this node was accessed or retrieved.
  DateTime? lastAccessed;

  /// The number of times this node has been accessed or retrieved.
  int frequency;

  /// An intrinsic importance score (0.0 to 1.0).
  ///
  /// This can be manually set or calculated based on the content type or
  /// user feedback.
  double importance;

  /// Creates a [Degree] instance with default values.
  Degree({
    this.lastAccessed,
    this.frequency = 0,
    this.importance = 0.5,
  });

  factory Degree.fromJson(Map<String, dynamic> json) => _$DegreeFromJson(json);
  Map<String, dynamic> toJson() => _$DegreeToJson(this);
}
