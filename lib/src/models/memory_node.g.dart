// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicalMetadata _$MedicalMetadataFromJson(Map<String, dynamic> json) =>
    MedicalMetadata(
      patientId: json['patientId'] as String?,
      specialty: json['specialty'] as String?,
      medicalRecordType: json['medicalRecordType'] as String?,
      encounterDate: json['encounterDate'] == null
          ? null
          : DateTime.parse(json['encounterDate'] as String),
      providerId: json['providerId'] as String?,
      consentGranted: json['consentGranted'] as bool? ?? false,
      encryptionLevel: json['encryptionLevel'] as String?,
      relevantNodes: (json['relevantNodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MedicalMetadataToJson(MedicalMetadata instance) =>
    <String, dynamic>{
      'patientId': instance.patientId,
      'specialty': instance.specialty,
      'medicalRecordType': instance.medicalRecordType,
      'encounterDate': instance.encounterDate?.toIso8601String(),
      'providerId': instance.providerId,
      'consentGranted': instance.consentGranted,
      'encryptionLevel': instance.encryptionLevel,
      'relevantNodes': instance.relevantNodes,
    };

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
      medicalMetadata: json['medicalMetadata'] == null
          ? null
          : MedicalMetadata.fromJson(
              json['medicalMetadata'] as Map<String, dynamic>),
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
      'medicalMetadata': instance.medicalMetadata?.toJson(),
      'embedding': instance.embedding?.toJson(),
      'degree': instance.degree?.toJson(),
    };
