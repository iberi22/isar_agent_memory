import 'memory_graph.dart';
import 'models/memory_edge.dart';

/// Summary of a maintenance operation.
class MemoryMaintenanceSummary {
  final int nodesRemoved;
  final int orphanEdgesRemoved;

  const MemoryMaintenanceSummary({
    this.nodesRemoved = 0,
    this.orphanEdgesRemoved = 0,
  });

  MemoryMaintenanceSummary merge(MemoryMaintenanceSummary other) {
    return MemoryMaintenanceSummary(
      nodesRemoved: nodesRemoved + other.nodesRemoved,
      orphanEdgesRemoved: orphanEdgesRemoved + other.orphanEdgesRemoved,
    );
  }
}

/// Periodic memory maintenance service using the standalone [MemoryGraph] API.
///
/// Provides pruning by source, age, count, and orphan edge cleanup.
/// Uses the existing API (deleteNode, getEdgesForNode, etc.) rather than
/// requiring custom methods on MemoryGraph.
class MemoryMaintenanceService {
  final MemoryGraph graph;

  MemoryMaintenanceService(this.graph);

  /// Delete all nodes whose metadata contains a matching [sources] entry.
  Future<MemoryMaintenanceSummary> pruneBySources(List<String> sources) async {
    final allNodes = await graph.isar.memoryNodes.where().findAll();
    int removed = 0;

    for (final node in allNodes) {
      final src = node.metadata?['source'] as String?;
      if (src != null && sources.contains(src)) {
        if (await graph.deleteNode(node.id)) removed++;
      }
    }

    final orphanEdges = await _deleteOrphanEdges();
    return MemoryMaintenanceSummary(
      nodesRemoved: removed,
      orphanEdgesRemoved: orphanEdges,
    );
  }

  /// Delete nodes older than [retention].
  Future<MemoryMaintenanceSummary> pruneByAge(
    Duration retention, {
    String? type,
  }) async {
    final cutoff = DateTime.now().subtract(retention);
    final allNodes = await graph.isar.memoryNodes.where().findAll();
    int removed = 0;

    for (final node in allNodes) {
      if (type != null && node.type != type) continue;
      if (node.createdAt.isBefore(cutoff)) {
        if (await graph.deleteNode(node.id)) removed++;
      }
    }

    final orphanEdges = await _deleteOrphanEdges();
    return MemoryMaintenanceSummary(
      nodesRemoved: removed,
      orphanEdgesRemoved: orphanEdges,
    );
  }

  /// Keep at most [maxEntries] nodes (removes oldest).
  Future<MemoryMaintenanceSummary> enforceRetention({
    required int maxEntries,
    String? type,
  }) async {
    var allNodes = await graph.isar.memoryNodes.where().findAll();
    if (type != null) {
      allNodes = allNodes.where((n) => n.type == type).toList();
    }
    if (allNodes.length <= maxEntries) {
      return const MemoryMaintenanceSummary();
    }

    // Sort oldest first
    allNodes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final toRemove = allNodes.take(allNodes.length - maxEntries);
    int removed = 0;

    for (final node in toRemove) {
      if (await graph.deleteNode(node.id)) removed++;
    }

    final orphanEdges = await _deleteOrphanEdges();
    return MemoryMaintenanceSummary(
      nodesRemoved: removed,
      orphanEdgesRemoved: orphanEdges,
    );
  }

  /// Remove edges whose from- or to-node no longer exists.
  Future<MemoryMaintenanceSummary> pruneOrphansOnly() async {
    final orphanEdges = await _deleteOrphanEdges();
    return MemoryMaintenanceSummary(orphanEdgesRemoved: orphanEdges);
  }

  /// Internal: find and delete edges referencing non-existent nodes.
  Future<int> _deleteOrphanEdges() async {
    final allEdges = await graph.isar.memoryEdges.where().findAll();
    final nodeIds = (await graph.isar.memoryNodes.where().findAll())
        .map((n) => n.id)
        .toSet();
    int removed = 0;

    for (final edge in allEdges) {
      if (!nodeIds.contains(edge.fromNodeId) ||
          !nodeIds.contains(edge.toNodeId)) {
        await graph.isar.writeTxn(() => graph.isar.memoryEdges.delete(edge.id));
        removed++;
      }
    }

    return removed;
  }
}
