// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_embedding.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryEmbedding _$MemoryEmbeddingFromJson(Map<String, dynamic> json) =>
    MemoryEmbedding(
      vector: (json['vector'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      provider: json['provider'] as String? ?? 'unknown',
      dimension: (json['dimension'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MemoryEmbeddingToJson(MemoryEmbedding instance) =>
    <String, dynamic>{
      'vector': instance.vector,
      'provider': instance.provider,
      'dimension': instance.dimension,
    };
