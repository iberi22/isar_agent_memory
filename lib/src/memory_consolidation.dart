import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'memory_graph.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';
import 'llm_adapter.dart';

/// Memory consolidation service for merging similar memories.
///
/// This service provides functionality to identify, merge, and consolidate
/// similar or related memory nodes to reduce redundancy and improve memory quality.
class MemoryConsolidation {
  final MemoryGraph memoryGraph;

  /// Threshold for considering two memories as similar (cosine distance).
  final double similarityThreshold;

  /// Minimum number of similar memories to trigger consolidation.
  final int minClusterSize;

  MemoryConsolidation(
    this.memoryGraph, {
    this.similarityThreshold = 0.15,
    this.minClusterSize = 3,
  });

  /// Finds clusters of similar memories based on embedding similarity.
  ///
  /// Returns a list of clusters, where each cluster is a list of node IDs.
  Future<List<List<int>>> findSimilarMemoryClusters({
    String? type,
    int? maxClusters,
  }) async {
    final nodes = await memoryGraph.isar.memoryNodes
        .filter()
        .optional(type != null, (q) => q.typeEqualTo(type))
        .findAll();

    if (nodes.length < minClusterSize) {
      return [];
    }

    final clusters = <List<int>>[];
    final processed = <int>{};

    for (final node in nodes) {
      if (processed.contains(node.id) || node.embedding == null) continue;

      final cluster = [node.id];
      processed.add(node.id);

      final vector = Float32List.fromList(
        node.embedding!.vector.map((e) => e.toDouble()).toList(),
      );

      // Find similar nodes
      final similar = await memoryGraph.semanticSearch(
        vector.toList(),
        topK: 50,
      );

      for (final result in similar) {
        if (!processed.contains(result.node.id) &&
            result.distance < similarityThreshold) {
          cluster.add(result.node.id);
          processed.add(result.node.id);
        }
      }

      if (cluster.length >= minClusterSize) {
        clusters.add(cluster);
        if (maxClusters != null && clusters.length >= maxClusters) {
          break;
        }
      }
    }

    return clusters;
  }

  /// Consolidates a cluster of similar memories into a single enhanced memory.
  ///
  /// Uses an LLM to generate a consolidated version that captures the essence
  /// of all memories in the cluster.
  ///
  /// [nodeIds]: The IDs of nodes to consolidate.
  /// [llmAdapter]: The LLM adapter for generating the consolidated content.
  /// [keepOriginals]: If true, keeps original nodes and links them to the consolidated node.
  ///
  /// Returns the ID of the consolidated memory node.
  Future<int> consolidateCluster({
    required List<int> nodeIds,
    required LLMAdapter llmAdapter,
    bool keepOriginals = true,
  }) async {
    if (nodeIds.isEmpty) {
      throw ArgumentError('Cannot consolidate empty cluster');
    }

    // Fetch all nodes
    final nodes = <MemoryNode>[];
    for (final id in nodeIds) {
      final node = await memoryGraph.getNode(id);
      if (node != null) nodes.add(node);
    }

    if (nodes.isEmpty) {
      throw StateError('No valid nodes found for consolidation');
    }

    // Generate consolidated content using LLM
    final prompt = _buildConsolidationPrompt(nodes);
    final consolidatedContent = await llmAdapter.generate(prompt);

    // Create consolidated node
    final consolidatedId = await memoryGraph.storeNodeWithEmbedding(
      content: consolidatedContent,
      type: 'consolidated',
      metadata: {
        'consolidated_from': nodeIds,
        'consolidation_date': DateTime.now().toIso8601String(),
        'source_count': nodes.length,
      },
    );

    // Create edges from consolidated node to originals
    if (keepOriginals) {
      for (final nodeId in nodeIds) {
        await memoryGraph.storeEdge(MemoryEdge(
          fromNodeId: consolidatedId,
          toNodeId: nodeId,
          relation: 'consolidated_from',
          metadata: {'consolidation_date': DateTime.now().toIso8601String()},
        ));
      }
    } else {
      // Delete original nodes if not keeping them
      for (final nodeId in nodeIds) {
        await memoryGraph.deleteNode(nodeId);
      }
    }

    return consolidatedId;
  }

  /// Builds a prompt for the LLM to consolidate multiple memories.
  String _buildConsolidationPrompt(List<MemoryNode> nodes) {
    final contents = nodes.map((n) => n.content).join('\n\n---\n\n');
    return '''You are a memory consolidation assistant. Your task is to merge the following related memories into a single, coherent memory that captures all important information without redundancy.

MEMORIES TO CONSOLIDATE:
$contents

Please provide a consolidated version that:
1. Preserves all unique information
2. Removes redundancy
3. Maintains chronological order if relevant
4. Is clear and concise

CONSOLIDATED MEMORY:''';
  }

  /// Runs automatic consolidation on the entire memory graph.
  ///
  /// Finds similar memory clusters and consolidates them automatically.
  ///
  /// Returns the number of clusters consolidated.
  Future<int> autoConsolidate({
    required LLMAdapter llmAdapter,
    String? type,
    int? maxClusters,
    bool keepOriginals = true,
  }) async {
    final clusters = await findSimilarMemoryClusters(
      type: type,
      maxClusters: maxClusters,
    );

    int consolidated = 0;
    for (final cluster in clusters) {
      try {
        await consolidateCluster(
          nodeIds: cluster,
          llmAdapter: llmAdapter,
          keepOriginals: keepOriginals,
        );
        consolidated++;
      } catch (e) {
        print('Failed to consolidate cluster: $e');
      }
    }

    return consolidated;
  }

  /// Merges duplicate memories (exact or near-exact matches).
  ///
  /// This is simpler than full consolidation and just removes duplicates.
  ///
  /// Returns the number of duplicates removed.
  Future<int> deduplicateMemories({
    double threshold = 0.05,
    String? type,
  }) async {
    final nodes = await memoryGraph.isar.memoryNodes
        .filter()
        .optional(type != null, (q) => q.typeEqualTo(type))
        .findAll();

    final toDelete = <int>{};
    final seen = <int>{};

    for (final node in nodes) {
      if (toDelete.contains(node.id) ||
          seen.contains(node.id) ||
          node.embedding == null) {
        continue;
      }

      seen.add(node.id);

      final vector = Float32List.fromList(
        node.embedding!.vector.map((e) => e.toDouble()).toList(),
      );

      final similar = await memoryGraph.semanticSearch(
        vector.toList(),
        topK: 10,
      );

      for (final result in similar) {
        if (result.node.id != node.id &&
            !toDelete.contains(result.node.id) &&
            result.distance < threshold) {
          // Keep the older memory (lower ID), delete the newer one
          if (result.node.id > node.id) {
            toDelete.add(result.node.id);
          }
        }
      }
    }

    // Delete duplicates
    for (final id in toDelete) {
      await memoryGraph.deleteNode(id);
    }

    return toDelete.length;
  }
}
