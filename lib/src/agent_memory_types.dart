import 'package:isar/isar.dart';
import 'memory_graph.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';

/// Agent memory system with episodic, semantic, and procedural memory types.
///
/// Implements different memory systems inspired by cognitive psychology.
class AgentMemoryTypes {
  final MemoryGraph memoryGraph;

  AgentMemoryTypes(this.memoryGraph);

  // Memory type constants
  static const String typeEpisodic = 'episodic';
  static const String typeSemantic = 'semantic';
  static const String typeProcedural = 'procedural';
  static const String typeWorking = 'working';

  /// Stores an episodic memory (event or experience).
  ///
  /// Episodic memories are tied to specific times and contexts.
  Future<int> storeEpisodicMemory({
    required String content,
    required DateTime timestamp,
    String? location,
    Map<String, dynamic>? context,
    List<String>? participants,
    double? emotionalValence,
  }) async {
    final metadata = {
      'memory_type': typeEpisodic,
      'timestamp': timestamp.toIso8601String(),
      if (location != null) 'location': location,
      if (participants != null) 'participants': participants,
      if (emotionalValence != null) 'emotional_valence': emotionalValence,
      ...?context,
    };

    return memoryGraph.storeNodeWithEmbedding(
      content: content,
      type: typeEpisodic,
      metadata: metadata,
    );
  }

  /// Stores a semantic memory (fact or concept).
  ///
  /// Semantic memories are context-free knowledge.
  Future<int> storeSemanticMemory({
    required String content,
    String? category,
    List<String>? tags,
    double? confidence,
    String? source,
  }) async {
    final metadata = {
      'memory_type': typeSemantic,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (confidence != null) 'confidence': confidence,
      if (source != null) 'source': source,
      'is_fact': true,
    };

    return memoryGraph.storeNodeWithEmbedding(
      content: content,
      type: typeSemantic,
      metadata: metadata,
      deduplicate: true, // Avoid duplicate facts
    );
  }

  /// Stores a procedural memory (skill or procedure).
  ///
  /// Procedural memories are "how to" knowledge.
  Future<int> storeProceduralMemory({
    required String procedure,
    required List<String> steps,
    String? skill,
    Map<String, dynamic>? preconditions,
    Map<String, dynamic>? postconditions,
    int? successCount,
    int? failureCount,
  }) async {
    final metadata = {
      'memory_type': typeProcedural,
      'steps': steps,
      if (skill != null) 'skill': skill,
      if (preconditions != null) 'preconditions': preconditions,
      if (postconditions != null) 'postconditions': postconditions,
      'success_count': successCount ?? 0,
      'failure_count': failureCount ?? 0,
      'proficiency':
          _calculateProficiency(successCount ?? 0, failureCount ?? 0),
    };

    return memoryGraph.storeNodeWithEmbedding(
      content: procedure,
      type: typeProcedural,
      metadata: metadata,
    );
  }

  /// Stores working memory (temporary, active information).
  ///
  /// Working memory has a TTL and is automatically cleared.
  Future<int> storeWorkingMemory({
    required String content,
    Duration ttl = const Duration(hours: 1),
    int? priority,
  }) async {
    final expiresAt = DateTime.now().add(ttl);

    final metadata = {
      'memory_type': typeWorking,
      'expires_at': expiresAt.toIso8601String(),
      'priority': priority ?? 5,
      'created_at': DateTime.now().toIso8601String(),
    };

    return memoryGraph.storeNodeWithEmbedding(
      content: content,
      type: typeWorking,
      metadata: metadata,
    );
  }

  /// Retrieves episodic memories from a time period.
  Future<List<MemoryNode>> getEpisodicMemories({
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    List<String>? participants,
  }) async {
    var query = memoryGraph.isar.memoryNodes.filter().typeEqualTo(typeEpisodic);

    final memories = await query.findAll();

    // Additional filtering based on metadata
    return memories.where((m) {
      final timestamp = m.metadata?['timestamp'];
      if (timestamp == null) return false;

      final memoryTime = DateTime.parse(timestamp);

      if (startTime != null && memoryTime.isBefore(startTime)) return false;
      if (endTime != null && memoryTime.isAfter(endTime)) return false;

      if (location != null && m.metadata?['location'] != location) return false;

      if (participants != null) {
        final memoryParticipants = m.metadata?['participants'] as List?;
        if (memoryParticipants == null) return false;
        if (!participants.any((p) => memoryParticipants.contains(p))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Retrieves semantic memories by category or tag.
  Future<List<MemoryNode>> getSemanticMemories({
    String? category,
    List<String>? tags,
    double? minConfidence,
  }) async {
    final memories = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeSemantic)
        .findAll();

    return memories.where((m) {
      if (category != null && m.metadata?['category'] != category) {
        return false;
      }

      if (tags != null) {
        final memoryTags = m.metadata?['tags'] as List?;
        if (memoryTags == null) return false;
        if (!tags.any((t) => memoryTags.contains(t))) return false;
      }

      if (minConfidence != null) {
        final confidence = m.metadata?['confidence'];
        if (confidence == null || confidence < minConfidence) return false;
      }

      return true;
    }).toList();
  }

  /// Retrieves procedural memories by skill.
  Future<List<MemoryNode>> getProceduralMemories({
    String? skill,
    double? minProficiency,
  }) async {
    final memories = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeProcedural)
        .findAll();

    return memories.where((m) {
      if (skill != null && m.metadata?['skill'] != skill) return false;

      if (minProficiency != null) {
        final proficiency = m.metadata?['proficiency'];
        if (proficiency == null || proficiency < minProficiency) return false;
      }

      return true;
    }).toList();
  }

  /// Updates proficiency of a procedural memory based on execution result.
  Future<void> updateProceduralProficiency({
    required int memoryId,
    required bool success,
  }) async {
    final node = await memoryGraph.getNode(memoryId);
    if (node == null || node.type != typeProcedural) return;

    node.metadata ??= {};
    final successCount = (node.metadata!['success_count'] ?? 0) as int;
    final failureCount = (node.metadata!['failure_count'] ?? 0) as int;

    if (success) {
      node.metadata!['success_count'] = successCount + 1;
    } else {
      node.metadata!['failure_count'] = failureCount + 1;
    }

    node.metadata!['proficiency'] = _calculateProficiency(
      node.metadata!['success_count'],
      node.metadata!['failure_count'],
    );

    node.metadata!['last_execution'] = DateTime.now().toIso8601String();

    await memoryGraph.storeNode(node);
  }

  /// Cleans up expired working memories.
  Future<int> cleanupWorkingMemory() async {
    final now = DateTime.now();
    final workingMemories = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeWorking)
        .findAll();

    int deleted = 0;

    for (final memory in workingMemories) {
      final expiresAt = memory.metadata?['expires_at'];
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (now.isAfter(expiry)) {
          await memoryGraph.deleteNode(memory.id);
          deleted++;
        }
      }
    }

    return deleted;
  }

  /// Converts episodic memory to semantic memory (consolidation).
  ///
  /// Extracts general knowledge from specific experiences.
  Future<int?> consolidateEpisodicToSemantic({
    required int episodicId,
    required String extractedKnowledge,
    String? category,
  }) async {
    final episodic = await memoryGraph.getNode(episodicId);
    if (episodic == null || episodic.type != typeEpisodic) return null;

    final semanticId = await storeSemanticMemory(
      content: extractedKnowledge,
      category: category,
      source: 'consolidated_from_episodic_$episodicId',
      confidence: 0.8,
    );

    // Create link between episodic and semantic
    final edge = MemoryEdge(
      fromNodeId: semanticId,
      toNodeId: episodicId,
      relation: 'consolidated_from',
    );
    await memoryGraph.storeEdge(edge);

    return semanticId;
  }

  /// Gets memory statistics by type.
  Future<MemoryTypeStats> getStats() async {
    final episodicCount = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeEpisodic)
        .count();

    final semanticCount = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeSemantic)
        .count();

    final proceduralCount = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeProcedural)
        .count();

    final workingCount = await memoryGraph.isar.memoryNodes
        .filter()
        .typeEqualTo(typeWorking)
        .count();

    return MemoryTypeStats(
      episodic: episodicCount,
      semantic: semanticCount,
      procedural: proceduralCount,
      working: workingCount,
    );
  }

  double _calculateProficiency(int success, int failure) {
    final total = success + failure;
    if (total == 0) return 0.0;
    return success / total;
  }
}

/// Statistics about memory types.
class MemoryTypeStats {
  final int episodic;
  final int semantic;
  final int procedural;
  final int working;

  MemoryTypeStats({
    required this.episodic,
    required this.semantic,
    required this.procedural,
    required this.working,
  });

  int get total => episodic + semantic + procedural + working;

  @override
  String toString() {
    return '''Memory Type Statistics:
  Episodic: $episodic
  Semantic: $semantic
  Procedural: $procedural
  Working: $working
  Total: $total''';
  }

  Map<String, dynamic> toJson() {
    return {
      'episodic': episodic,
      'semantic': semantic,
      'procedural': procedural,
      'working': working,
      'total': total,
    };
  }
}
