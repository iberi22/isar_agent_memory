// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_embedding.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MemoryEmbeddingSchema = Schema(
  name: r'MemoryEmbedding',
  id: -4127158395713779796,
  properties: {
    r'dimension': PropertySchema(
      id: 0,
      name: r'dimension',
      type: IsarType.long,
    ),
    r'provider': PropertySchema(
      id: 1,
      name: r'provider',
      type: IsarType.string,
    ),
    r'vector': PropertySchema(
      id: 2,
      name: r'vector',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _memoryEmbeddingEstimateSize,
  serialize: _memoryEmbeddingSerialize,
  deserialize: _memoryEmbeddingDeserialize,
  deserializeProp: _memoryEmbeddingDeserializeProp,
);

int _memoryEmbeddingEstimateSize(
  MemoryEmbedding object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.provider.length * 3;
  bytesCount += 3 + object.vector.length * 8;
  return bytesCount;
}

void _memoryEmbeddingSerialize(
  MemoryEmbedding object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dimension);
  writer.writeString(offsets[1], object.provider);
  writer.writeDoubleList(offsets[2], object.vector);
}

MemoryEmbedding _memoryEmbeddingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MemoryEmbedding(
    dimension: reader.readLongOrNull(offsets[0]) ?? 0,
    provider: reader.readStringOrNull(offsets[1]) ?? 'unknown',
    vector: reader.readDoubleList(offsets[2]) ?? const [],
  );
  return object;
}

P _memoryEmbeddingDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? 'unknown') as P;
    case 2:
      return (reader.readDoubleList(offset) ?? const []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MemoryEmbeddingQueryFilter
    on QueryBuilder<MemoryEmbedding, MemoryEmbedding, QFilterCondition> {
  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      dimensionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dimension',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      dimensionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dimension',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      dimensionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dimension',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      dimensionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dimension',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'provider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      providerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vector',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MemoryEmbedding, MemoryEmbedding, QAfterFilterCondition>
      vectorLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension MemoryEmbeddingQueryObject
    on QueryBuilder<MemoryEmbedding, MemoryEmbedding, QFilterCondition> {}

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
