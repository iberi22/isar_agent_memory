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

  /// Automatically summarizes a given layer by grouping nodes and using an LLM.
  ///
  /// [layerIndex]: The layer to summarize.
  /// [llmAdapter]: The adapter to the Large Language Model for summary generation.
  /// [promptTemplate]: A function to format the content into a prompt for the LLM.
  /// If null, a default template is used.
  ///
  /// Returns the ID of the newly created summary node.
  Future<int> autoSummarizeLayer({
    required int layerIndex,
    required LLMAdapter llmAdapter,
    String Function(String content)? promptTemplate,
  }) async {
    // 1. Get all nodes in the target layer
    final nodes = await getNodesByLayer(layerIndex);
    if (nodes.isEmpty) {
      throw Exception('No nodes found in layer $layerIndex to summarize.');
    }

    // 2. Combine content for the LLM prompt
    final contentToSummarize = nodes.map((n) => n.content).join('\n---\n');
    final prompt = promptTemplate != null
        ? promptTemplate(contentToSummarize)
        : 'Summarize the following content into a coherent paragraph: \n\n$contentToSummarize';

    // 3. Call LLM to generate summary
    final summaryContent = await llmAdapter.generate(prompt);

    // 4. Create the summary node in the next layer
    final childNodeIds = nodes.map((n) => n.id).toList();
    final summaryNodeId = await createSummaryNode(
      summaryContent: summaryContent,
      childNodeIds: childNodeIds,
      layer: layerIndex + 1,
    );

    // 5. Create 'part_of' relationships from the summary to its parts
    for (final childId in childNodeIds) {
      await storeEdge(MemoryEdge(
        fromNodeId: summaryNodeId,
        toNodeId: childId,
        relation: relationPartOf,
      ));
    }

    return summaryNodeId;
  }

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

  /// Performs a multi-hop search, enriching results with hierarchical context.
  ///
  /// [queryEmbedding]: The embedding of the search query.
  /// [maxHops]: The maximum number of upward traversals (default is 2).
  /// [topK]: The number of initial results to fetch from the base layer.
  ///
  /// Returns a list of enriched results, where each result includes the base node
  /// and a list of parent (summary) nodes.
  Future<List<({MemoryNode node, List<MemoryNode> context})>> multiHopSearch({
    required List<double> queryEmbedding,
    int maxHops = 2,
    int topK = 5,
  }) async {
    // 1. Semantic search on the base layer (layer 0)
    final initialResults =
        await semanticSearch(queryEmbedding, topK: topK, layer: 0);

    final enrichedResults = <({MemoryNode node, List<MemoryNode> context})>[];

    // 2. Traverse upwards for each result
    for (final result in initialResults) {
      final baseNode = result.node;
      final context = <MemoryNode>[];
      var currentNode = baseNode;
      var hops = 0;

      while (hops < maxHops) {
        // Find edges where the current node is the 'from' node and relation is 'summary_of'
        final edges = await isar.memoryEdges
            .filter()
            .fromNodeIdEqualTo(currentNode.id)
            .relationEqualTo(relationSummaryOf)
            .findAll();

        if (edges.isEmpty) break;

        // Follow the first summary edge to the parent
        final parentNodeId = edges.first.toNodeId;
        final parentNode = await getNode(parentNodeId);

        if (parentNode == null) break;

        context.add(parentNode);
        currentNode = parentNode;
        hops++;
      }
      enrichedResults.add((node: baseNode, context: context));
    }

    return enrichedResults;
  }
}
