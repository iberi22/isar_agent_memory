// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_edge.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMemoryEdgeCollection on Isar {
  IsarCollection<MemoryEdge> get memoryEdges => this.collection();
}

const MemoryEdgeSchema = CollectionSchema(
  name: r'MemoryEdge',
  id: 2749767584170770699,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fromNodeId': PropertySchema(
      id: 1,
      name: r'fromNodeId',
      type: IsarType.long,
    ),
    r'relation': PropertySchema(
      id: 2,
      name: r'relation',
      type: IsarType.string,
    ),
    r'toNodeId': PropertySchema(
      id: 3,
      name: r'toNodeId',
      type: IsarType.long,
    ),
    r'weight': PropertySchema(
      id: 4,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _memoryEdgeEstimateSize,
  serialize: _memoryEdgeSerialize,
  deserialize: _memoryEdgeDeserialize,
  deserializeProp: _memoryEdgeDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _memoryEdgeGetId,
  getLinks: _memoryEdgeGetLinks,
  attach: _memoryEdgeAttach,
  version: '3.1.0+1',
);

int _memoryEdgeEstimateSize(
  MemoryEdge object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.relation.length * 3;
  return bytesCount;
}

void _memoryEdgeSerialize(
  MemoryEdge object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.fromNodeId);
  writer.writeString(offsets[2], object.relation);
  writer.writeLong(offsets[3], object.toNodeId);
  writer.writeDouble(offsets[4], object.weight);
}

MemoryEdge _memoryEdgeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MemoryEdge(
    fromNodeId: reader.readLong(offsets[1]),
    relation: reader.readString(offsets[2]),
    toNodeId: reader.readLong(offsets[3]),
    weight: reader.readDoubleOrNull(offsets[4]),
  );
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  return object;
}

P _memoryEdgeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _memoryEdgeGetId(MemoryEdge object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _memoryEdgeGetLinks(MemoryEdge object) {
  return [];
}

void _memoryEdgeAttach(IsarCollection<dynamic> col, Id id, MemoryEdge object) {
  object.id = id;
}

extension MemoryEdgeQueryWhereSort
    on QueryBuilder<MemoryEdge, MemoryEdge, QWhere> {
  QueryBuilder<MemoryEdge, MemoryEdge, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MemoryEdgeQueryWhere
    on QueryBuilder<MemoryEdge, MemoryEdge, QWhereClause> {
  QueryBuilder<MemoryEdge, MemoryEdge, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MemoryEdgeQueryFilter
    on QueryBuilder<MemoryEdge, MemoryEdge, QFilterCondition> {
  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> fromNodeIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromNodeId',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      fromNodeIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fromNodeId',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      fromNodeIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fromNodeId',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> fromNodeIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fromNodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> relationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      relationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> relationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> relationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      relationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> relationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> relationContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> relationMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      relationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relation',
        value: '',
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      relationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relation',
        value: '',
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> toNodeIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toNodeId',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      toNodeIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toNodeId',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> toNodeIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toNodeId',
        value: value,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> toNodeIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toNodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition>
      weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterFilterCondition> weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension MemoryEdgeQueryObject
    on QueryBuilder<MemoryEdge, MemoryEdge, QFilterCondition> {}

extension MemoryEdgeQueryLinks
    on QueryBuilder<MemoryEdge, MemoryEdge, QFilterCondition> {}

extension MemoryEdgeQuerySortBy
    on QueryBuilder<MemoryEdge, MemoryEdge, QSortBy> {
  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByFromNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromNodeId', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByFromNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromNodeId', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByRelation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relation', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByRelationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relation', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByToNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toNodeId', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByToNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toNodeId', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension MemoryEdgeQuerySortThenBy
    on QueryBuilder<MemoryEdge, MemoryEdge, QSortThenBy> {
  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByFromNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromNodeId', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByFromNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromNodeId', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByRelation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relation', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByRelationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relation', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByToNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toNodeId', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByToNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toNodeId', Sort.desc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension MemoryEdgeQueryWhereDistinct
    on QueryBuilder<MemoryEdge, MemoryEdge, QDistinct> {
  QueryBuilder<MemoryEdge, MemoryEdge, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QDistinct> distinctByFromNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromNodeId');
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QDistinct> distinctByRelation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relation', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QDistinct> distinctByToNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toNodeId');
    });
  }

  QueryBuilder<MemoryEdge, MemoryEdge, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension MemoryEdgeQueryProperty
    on QueryBuilder<MemoryEdge, MemoryEdge, QQueryProperty> {
  QueryBuilder<MemoryEdge, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MemoryEdge, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MemoryEdge, int, QQueryOperations> fromNodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromNodeId');
    });
  }

  QueryBuilder<MemoryEdge, String, QQueryOperations> relationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relation');
    });
  }

  QueryBuilder<MemoryEdge, int, QQueryOperations> toNodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toNodeId');
    });
  }

  QueryBuilder<MemoryEdge, double?, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
