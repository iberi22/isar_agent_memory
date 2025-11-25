import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

/// Extension for HiRAG (Hierarchical RAG) capabilities.
///
/// This extension adds methods to manage hierarchical layers of knowledge.
extension HierarchicalMemoryGraph on MemoryGraph {

  /// Relation type for summary edges (Child -> Summary).
  static const String relationSummaryOf = 'summary_of';

  /// Relation type for part-of edges (Part -> Whole).
  static const String relationPartOf = 'part_of';

  /// Creates a summary node for a list of [childNodeIds].
  ///
  /// [summaryContent]: The summarized text.
  /// [layer]: The layer of the summary node (should be child layer + 1).
  ///
  /// Returns the ID of the new summary node.
  Future<int> createSummaryNode({
    required String summaryContent,
    required List<int> childNodeIds,
    required int layer,
    String? type = 'summary',
  }) async {
    final summaryId = await storeNodeWithEmbedding(
      content: summaryContent,
      type: type,
      // Pass metadata via a method that supports it if needed,
      // or update node after creation.
      // storeNodeWithEmbedding supports metadata.
      metadata: {'is_summary': true},
    );

    // Update layer
    final node = await getNode(summaryId);
    if (node != null) {
      node.layer = layer;
      await storeNode(node);
    }

    // Create edges
    for (final childId in childNodeIds) {
      await storeEdge(MemoryEdge(
        fromNodeId: childId,
        toNodeId: summaryId,
        relation: relationSummaryOf,
      ));
    }

    return summaryId;
  }

  /// Retrieves nodes by [layer].
  Future<List<MemoryNode>> getNodesByLayer(int layer) async {
    return await isar.memoryNodes.filter().layerEqualTo(layer).findAll();
  }
}
