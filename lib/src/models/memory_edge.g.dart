// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_edge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryEdge _$MemoryEdgeFromJson(Map<String, dynamic> json) => MemoryEdge(
      fromNodeId: (json['fromNodeId'] as num).toInt(),
      toNodeId: (json['toNodeId'] as num).toInt(),
      relation: json['relation'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      version: json['version'] as String?,
      deviceId: json['deviceId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      uuid: json['uuid'] as String?,
    )..createdAt = DateTime.parse(json['createdAt'] as String);

Map<String, dynamic> _$MemoryEdgeToJson(MemoryEdge instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'fromNodeId': instance.fromNodeId,
      'toNodeId': instance.toNodeId,
      'relation': instance.relation,
      'weight': instance.weight,
      'createdAt': instance.createdAt.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'version': instance.version,
      'deviceId': instance.deviceId,
      'isDeleted': instance.isDeleted,
    };
