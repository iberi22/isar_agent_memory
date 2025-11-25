import 'dart:math' as math;
import 'package:isar/isar.dart';
import 'memory_graph.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';

/// Service for forgetting (removing) irrelevant or outdated memories.
///
/// Implements various strategies for memory decay and cleanup.
class ForgettingMechanism {
  final MemoryGraph memoryGraph;

  ForgettingMechanism(this.memoryGraph);

  /// Calculates importance score for a memory node.
  ///
  /// Higher scores = more important = less likely to be forgotten.
  Future<double> calculateImportance(MemoryNode node) async {
    double score = 0.0;

    // Factor 1: Recency (newer memories are more important)
    final age = DateTime.now().difference(node.createdAt);
    final recencyScore = math.exp(-age.inDays / 30.0); // Decay over ~30 days
    score += recencyScore * 0.3;

    // Factor 2: Access frequency (how often was it retrieved)
    final accessCount = node.metadata?['access_count'] ?? 0;
    final accessScore =
        math.min<double>(1.0, (accessCount as num).toDouble() / 10.0);
    score += accessScore * 0.3;

    // Factor 3: Connection strength (well-connected nodes are important)
    final incomingEdges = await memoryGraph.isar.memoryEdges
        .filter()
        .toNodeIdEqualTo(node.id)
        .count();
    final outgoingEdges = await memoryGraph.isar.memoryEdges
        .filter()
        .fromNodeIdEqualTo(node.id)
        .count();
    final connectionScore =
        math.min(1.0, (incomingEdges + outgoingEdges) / 5.0);
    score += connectionScore * 0.2;

    // Factor 4: Explicit importance flag
    final explicitImportance = node.metadata?['importance'] ?? 0.5;
    score += explicitImportance * 0.2;

    return score;
  }

  /// Forgets (deletes) memories below a certain importance threshold.
  ///
  /// [threshold]: Importance score below which memories are forgotten (0-1).
  /// [dryRun]: If true, returns what would be deleted without actually deleting.
  ///
  /// Returns the list of node IDs that were (or would be) forgotten.
  Future<List<int>> forgetByImportance({
    required double threshold,
    bool dryRun = false,
    String? type,
  }) async {
    final nodes = await memoryGraph.isar.memoryNodes
        .filter()
        .optional(type != null, (q) => q.typeEqualTo(type))
        .findAll();

    final toForget = <int>[];

    for (final node in nodes) {
      // Don't forget protected memories
      if (node.metadata?['protected'] == true) continue;

      final importance = await calculateImportance(node);
      if (importance < threshold) {
        toForget.add(node.id);
      }
    }

    if (!dryRun) {
      for (final id in toForget) {
        await memoryGraph.deleteNode(id);
      }
    }

    return toForget;
  }

  /// Forgets memories older than a certain age.
  ///
  /// [maxAge]: Maximum age in days.
  /// [keepImportant]: If true, keeps memories with high importance regardless of age.
  /// [importanceThreshold]: Threshold for keeping important old memories.
  Future<List<int>> forgetByAge({
    required int maxAgeDays,
    bool keepImportant = true,
    double importanceThreshold = 0.7,
    bool dryRun = false,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));

    final oldNodes = await memoryGraph.isar.memoryNodes
        .filter()
        .createdAtLessThan(cutoff)
        .findAll();

    final toForget = <int>[];

    for (final node in oldNodes) {
      // Check protection
      if (node.metadata?['protected'] == true) continue;

      // Check importance if keepImportant is true
      if (keepImportant) {
        final importance = await calculateImportance(node);
        if (importance >= importanceThreshold) continue;
      }

      toForget.add(node.id);
    }

    if (!dryRun) {
      for (final id in toForget) {
        await memoryGraph.deleteNode(id);
      }
    }

    return toForget;
  }

  /// Implements temporal decay: reduces importance of memories over time.
  ///
  /// Updates metadata['importance'] based on age and access patterns.
  Future<int> applyTemporalDecay({
    double decayRate = 0.1,
    int minAccessCount = 0,
  }) async {
    final nodes = await memoryGraph.isar.memoryNodes.where().findAll();
    int updated = 0;

    for (final node in nodes) {
      if (node.metadata?['protected'] == true) continue;

      final age = DateTime.now().difference(node.createdAt);
      final accessCount = node.metadata?['access_count'] ?? 0;

      // Skip recently accessed memories
      if (accessCount > minAccessCount) continue;

      // Calculate decay
      final currentImportance = node.metadata?['importance'] ?? 0.5;
      final decayFactor = math.exp(-decayRate * age.inDays / 30.0);
      final newImportance = currentImportance * decayFactor;

      // Update node
      node.metadata ??= {};
      node.metadata!['importance'] = newImportance;
      node.metadata!['last_decay'] = DateTime.now().toIso8601String();

      await memoryGraph.storeNode(node);
      updated++;
    }

    return updated;
  }

  /// Forgets least recently used (LRU) memories when storage limit is reached.
  ///
  /// [maxNodes]: Maximum number of nodes to keep.
  Future<List<int>> forgetLRU({
    required int maxNodes,
    bool dryRun = false,
  }) async {
    final totalNodes = await memoryGraph.isar.memoryNodes.count();

    if (totalNodes <= maxNodes) {
      return []; // Under limit, nothing to forget
    }

    final toForgetCount = totalNodes - maxNodes;

    // Get nodes sorted by last access time (oldest first)
    final nodes =
        await memoryGraph.isar.memoryNodes.where().sortByModifiedAt().findAll();

    final toForget = <int>[];
    int forgotten = 0;

    for (final node in nodes) {
      if (forgotten >= toForgetCount) break;
      if (node.metadata?['protected'] == true) continue;

      toForget.add(node.id);
      forgotten++;
    }

    if (!dryRun) {
      for (final id in toForget) {
        await memoryGraph.deleteNode(id);
      }
    }

    return toForget;
  }

  /// Auto-forget: combines multiple strategies for intelligent cleanup.
  ///
  /// This is the recommended method for periodic memory maintenance.
  Future<ForgettingReport> autoForget({
    int? maxNodes,
    int? maxAgeDays,
    double? minImportance,
    bool applyDecay = true,
    bool dryRun = false,
  }) async {
    final report = ForgettingReport(startTime: DateTime.now());

    // Step 1: Apply temporal decay
    if (applyDecay) {
      report.nodesDecayed = await applyTemporalDecay();
    }

    // Step 2: Forget by age
    if (maxAgeDays != null) {
      final forgotten = await forgetByAge(
        maxAgeDays: maxAgeDays,
        dryRun: dryRun,
      );
      report.forgottenByAge.addAll(forgotten);
    }

    // Step 3: Forget by importance
    if (minImportance != null) {
      final forgotten = await forgetByImportance(
        threshold: minImportance,
        dryRun: dryRun,
      );
      report.forgottenByImportance.addAll(forgotten);
    }

    // Step 4: Enforce storage limit
    if (maxNodes != null) {
      final forgotten = await forgetLRU(
        maxNodes: maxNodes,
        dryRun: dryRun,
      );
      report.forgottenByLRU.addAll(forgotten);
    }

    report.endTime = DateTime.now();
    return report;
  }

  /// Marks a memory as protected (never forgotten).
  Future<void> protect(int nodeId) async {
    final node = await memoryGraph.getNode(nodeId);
    if (node != null) {
      node.metadata ??= {};
      node.metadata!['protected'] = true;
      await memoryGraph.storeNode(node);
    }
  }

  /// Unmarks a memory as protected.
  Future<void> unprotect(int nodeId) async {
    final node = await memoryGraph.getNode(nodeId);
    if (node != null) {
      node.metadata ??= {};
      node.metadata!['protected'] = false;
      await memoryGraph.storeNode(node);
    }
  }

  /// Records that a memory was accessed (for LRU tracking).
  Future<void> recordAccess(int nodeId) async {
    final node = await memoryGraph.getNode(nodeId);
    if (node != null) {
      node.metadata ??= {};
      node.metadata!['access_count'] =
          (node.metadata!['access_count'] ?? 0) + 1;
      node.metadata!['last_access'] = DateTime.now().toIso8601String();
      node.modifiedAt = DateTime.now();
      await memoryGraph.storeNode(node);
    }
  }
}

/// Report from auto-forget operation.
class ForgettingReport {
  final DateTime startTime;
  DateTime? endTime;
  int nodesDecayed = 0;
  final List<int> forgottenByAge = [];
  final List<int> forgottenByImportance = [];
  final List<int> forgottenByLRU = [];

  ForgettingReport({required this.startTime});

  int get totalForgotten =>
      forgottenByAge.length +
      forgottenByImportance.length +
      forgottenByLRU.length;

  Duration get duration =>
      endTime != null ? endTime!.difference(startTime) : Duration.zero;

  @override
  String toString() {
    return '''Forgetting Report:
Duration: ${duration.inMilliseconds}ms
Nodes decayed: $nodesDecayed
Forgotten by age: ${forgottenByAge.length}
Forgotten by importance: ${forgottenByImportance.length}
Forgotten by LRU: ${forgottenByLRU.length}
Total forgotten: $totalForgotten''';
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'nodesDecayed': nodesDecayed,
      'forgottenByAge': forgottenByAge,
      'forgottenByImportance': forgottenByImportance,
      'forgottenByLRU': forgottenByLRU,
      'totalForgotten': totalForgotten,
    };
  }
}
