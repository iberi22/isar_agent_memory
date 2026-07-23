// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryNode _$MemoryNodeFromJson(Map<String, dynamic> json) => MemoryNode(
      content: json['content'] as String,
      type: json['type'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      embedding: json['embedding'] == null
          ? null
          : MemoryEmbedding.fromJson(json['embedding'] as Map<String, dynamic>),
      degree: json['degree'] == null
          ? null
          : Degree.fromJson(json['degree'] as Map<String, dynamic>),
      version: json['version'] as String?,
      deviceId: json['deviceId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      layer: (json['layer'] as num?)?.toInt() ?? 0,
      uuid: json['uuid'] as String?,
      accessCount: (json['accessCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MemoryNodeToJson(MemoryNode instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'content': instance.content,
      'type': instance.type,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'accessCount': instance.accessCount,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'version': instance.version,
      'deviceId': instance.deviceId,
      'isDeleted': instance.isDeleted,
      'layer': instance.layer,
      'embedding': instance.embedding?.toJson(),
      'degree': instance.degree?.toJson(),
    };
