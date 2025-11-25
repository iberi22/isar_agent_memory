import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'memory_graph.dart';
import 'models/memory_node.dart';
import 'hierarchical_graph.dart';
import 'llm_adapter.dart';

/// Extension for dynamic layer management in HiRAG.
///
/// Automatically creates and manages hierarchical layers based on content.
extension DynamicLayerCreation on MemoryGraph {
  /// Automatically organizes nodes into hierarchical layers.
  ///
  /// Uses clustering and abstraction to create a dynamic layer structure.
  Future<LayerOrganization> organizeIntoLayers({
    required LLMAdapter llmAdapter,
    int maxNodesPerLayer = 20,
    double similarityThreshold = 0.3,
    int maxLayers = 5,
  }) async {
    final organization = LayerOrganization();

    // Get all base nodes (layer 0)
    final baseNodes = await isar.memoryNodes.filter().layerEqualTo(0).findAll();

    if (baseNodes.isEmpty) {
      return organization;
    }

    organization.addLayer(0, baseNodes.map((n) => n.id).toList());

    // Build layers bottom-up
    var currentLayer = 0;
    var currentNodes = baseNodes;

    while (currentLayer < maxLayers && currentNodes.length > maxNodesPerLayer) {
      // Cluster nodes in current layer
      final clusters = await _clusterNodes(
        currentNodes,
        maxClusterSize: maxNodesPerLayer,
        similarityThreshold: similarityThreshold,
      );

      if (clusters.isEmpty || clusters.length >= currentNodes.length) {
        break; // Can't reduce further
      }

      // Create summary nodes for each cluster
      final nextLayerNodes = <MemoryNode>[];

      for (final _ in clusters) {
        final summaryId = await autoSummarizeLayer(
          layerIndex: currentLayer,
          llmAdapter: llmAdapter,
        );

        final summaryNode = await getNode(summaryId);
        if (summaryNode != null) {
          summaryNode.layer = currentLayer + 1;
          await storeNode(summaryNode);
          nextLayerNodes.add(summaryNode);
        }
      }

      currentLayer++;
      currentNodes = nextLayerNodes;
      organization.addLayer(
          currentLayer, currentNodes.map((n) => n.id).toList());
    }

    return organization;
  }

  /// Clusters nodes based on embedding similarity.
  Future<List<List<MemoryNode>>> _clusterNodes(
    List<MemoryNode> nodes, {
    required int maxClusterSize,
    required double similarityThreshold,
  }) async {
    if (nodes.isEmpty) return [];

    final clusters = <List<MemoryNode>>[];
    final unassigned = List<MemoryNode>.from(nodes);

    while (unassigned.isNotEmpty) {
      final seed = unassigned.removeAt(0);
      final cluster = [seed];

      if (seed.embedding == null) {
        clusters.add(cluster);
        continue;
      }

      final seedVector = Float32List.fromList(
        seed.embedding!.vector.map((e) => e.toDouble()).toList(),
      );

      // Find similar nodes for this cluster
      final toRemove = <MemoryNode>[];

      for (final node in unassigned) {
        if (cluster.length >= maxClusterSize) break;
        if (node.embedding == null) continue;

        final nodeVector = Float32List.fromList(
          node.embedding!.vector.map((e) => e.toDouble()).toList(),
        );

        final similarity = _cosineSimilarity(seedVector, nodeVector);

        if (similarity >= similarityThreshold) {
          cluster.add(node);
          toRemove.add(node);
        }
      }

      unassigned.removeWhere((n) => toRemove.contains(n));
      clusters.add(cluster);
    }

    return clusters;
  }

  /// Calculates cosine similarity between two vectors.
  double _cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (_sqrt(normA) * _sqrt(normB));
  }

  double _sqrt(double x) {
    if (x < 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Dynamically adjusts layer structure based on query patterns.
  ///
  /// Creates new intermediate layers if queries frequently span multiple layers.
  Future<void> optimizeLayerStructure({
    required LLMAdapter llmAdapter,
    List<int>? frequentlyAccessedNodes,
  }) async {
    if (frequentlyAccessedNodes == null || frequentlyAccessedNodes.isEmpty) {
      return;
    }

    // Analyze which layers are frequently queried together
    final layerAccess = <int, int>{};

    for (final nodeId in frequentlyAccessedNodes) {
      final node = await getNode(nodeId);
      if (node != null) {
        layerAccess[node.layer] = (layerAccess[node.layer] ?? 0) + 1;
      }
    }

    // Identify layer gaps that need intermediate layers
    final sortedLayers = layerAccess.keys.toList()..sort();

    for (int i = 0; i < sortedLayers.length - 1; i++) {
      final currentLayer = sortedLayers[i];
      final nextLayer = sortedLayers[i + 1];

      // If there's a gap > 1, consider creating intermediate layer
      if (nextLayer - currentLayer > 1) {
        await _createIntermediateLayer(
          lowerLayer: currentLayer,
          upperLayer: nextLayer,
          llmAdapter: llmAdapter,
        );
      }
    }
  }

  /// Creates an intermediate layer between two existing layers.
  Future<void> _createIntermediateLayer({
    required int lowerLayer,
    required int upperLayer,
    required LLMAdapter llmAdapter,
  }) async {
    final intermediateLayer = lowerLayer + 1;

    // Get nodes from lower layer
    final lowerNodes = await getNodesByLayer(lowerLayer);
    if (lowerNodes.isEmpty) return;

    // Create intermediate summaries
    final summaryId = await autoSummarizeLayer(
      layerIndex: lowerLayer,
      llmAdapter: llmAdapter,
    );

    // Update summary node's layer
    final summaryNode = await getNode(summaryId);
    if (summaryNode != null) {
      summaryNode.layer = intermediateLayer;
      await storeNode(summaryNode);
    }

    // Shift upper layers up by 1
    final upperNodes =
        await isar.memoryNodes.filter().layerGreaterThan(lowerLayer).findAll();

    for (final node in upperNodes) {
      node.layer = node.layer + 1;
      await storeNode(node);
    }
  }

  /// Analyzes layer distribution and suggests optimizations.
  Future<LayerAnalysis> analyzeLayerStructure() async {
    final allNodes = await isar.memoryNodes.where().findAll();

    final layerCounts = <int, int>{};
    final layerTypes = <int, Set<String>>{};

    int maxLayer = 0;

    for (final node in allNodes) {
      layerCounts[node.layer] = (layerCounts[node.layer] ?? 0) + 1;

      layerTypes.putIfAbsent(node.layer, () => <String>{});
      if (node.type != null) {
        layerTypes[node.layer]!.add(node.type!);
      }

      if (node.layer > maxLayer) maxLayer = node.layer;
    }

    return LayerAnalysis(
      totalNodes: allNodes.length,
      totalLayers: maxLayer + 1,
      nodesPerLayer: layerCounts,
      typesPerLayer: layerTypes.map((k, v) => MapEntry(k, v.toList())),
    );
  }
}

/// Result of layer organization.
class LayerOrganization {
  final Map<int, List<int>> layerNodes = {};

  void addLayer(int layer, List<int> nodeIds) {
    layerNodes[layer] = nodeIds;
  }

  int get totalLayers => layerNodes.length;
  int get totalNodes =>
      layerNodes.values.fold(0, (sum, list) => sum + list.length);

  @override
  String toString() {
    final buffer = StringBuffer('Layer Organization:\n');
    for (final entry in layerNodes.entries) {
      buffer.writeln('  Layer ${entry.key}: ${entry.value.length} nodes');
    }
    return buffer.toString();
  }
}

/// Analysis of layer structure.
class LayerAnalysis {
  final int totalNodes;
  final int totalLayers;
  final Map<int, int> nodesPerLayer;
  final Map<int, List<String>> typesPerLayer;

  LayerAnalysis({
    required this.totalNodes,
    required this.totalLayers,
    required this.nodesPerLayer,
    required this.typesPerLayer,
  });

  double get averageNodesPerLayer =>
      totalLayers > 0 ? totalNodes / totalLayers : 0.0;

  List<String> get recommendations {
    final recs = <String>[];

    // Check for empty layers
    for (int i = 0; i < totalLayers; i++) {
      if (!nodesPerLayer.containsKey(i) || nodesPerLayer[i] == 0) {
        recs.add('Layer $i is empty - consider consolidating layers');
      }
    }

    // Check for imbalanced layers
    final counts = nodesPerLayer.values.toList();
    if (counts.isNotEmpty) {
      final maxNodes = counts.reduce((a, b) => a > b ? a : b);
      final minNodes = counts.reduce((a, b) => a < b ? a : b);

      if (maxNodes > minNodes * 5) {
        recs.add('Layers are imbalanced - consider redistributing nodes');
      }
    }

    // Check for too many layers
    if (totalLayers > 10) {
      recs.add('Too many layers ($totalLayers) - consider consolidation');
    }

    // Check for too few layers
    if (totalLayers < 3 && totalNodes > 100) {
      recs.add('Consider adding more layers for better organization');
    }

    return recs;
  }

  @override
  String toString() {
    final buffer = StringBuffer('Layer Analysis:\n');
    buffer.writeln('Total Nodes: $totalNodes');
    buffer.writeln('Total Layers: $totalLayers');
    buffer.writeln(
        'Average Nodes per Layer: ${averageNodesPerLayer.toStringAsFixed(1)}');
    buffer.writeln('\nNodes per Layer:');
    for (final entry in nodesPerLayer.entries) {
      buffer.writeln('  Layer ${entry.key}: ${entry.value} nodes');
    }

    if (recommendations.isNotEmpty) {
      buffer.writeln('\nRecommendations:');
      for (final rec in recommendations) {
        buffer.writeln('  • $rec');
      }
    }

    return buffer.toString();
  }
}
