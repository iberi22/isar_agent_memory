import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory_embedding.g.dart';

/// Represents a vector embedding for a [MemoryNode].
///
/// Wraps the raw vector data along with metadata about the provider and dimension.
@embedded
@JsonSerializable()
class MemoryEmbedding {
  /// The raw floating-point vector data.
  ///
  /// Isar stores `List<double>` efficiently.
  final List<double> vector;

  /// The name of the provider or model that generated this embedding (e.g., 'gemini', 'openai').
  final String provider;

  /// The dimension of the vector (e.g., 768, 1536).
  final int dimension;

  /// Creates a [MemoryEmbedding].
  MemoryEmbedding({
    this.vector = const [],
    this.provider = 'unknown',
    this.dimension = 0,
  });

  factory MemoryEmbedding.fromJson(Map<String, dynamic> json) =>
      _$MemoryEmbeddingFromJson(json);
  Map<String, dynamic> toJson() => _$MemoryEmbeddingToJson(this);
}
