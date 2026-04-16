// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'degree.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Degree _$DegreeFromJson(Map<String, dynamic> json) => Degree(
      lastAccessed: json['lastAccessed'] == null
          ? null
          : DateTime.parse(json['lastAccessed'] as String),
      frequency: (json['frequency'] as num?)?.toInt() ?? 0,
      importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$DegreeToJson(Degree instance) => <String, dynamic>{
      'lastAccessed': instance.lastAccessed?.toIso8601String(),
      'frequency': instance.frequency,
      'importance': instance.importance,
    };
