import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:dvdb/dvdb.dart' as dvdb;
import 'embeddings_adapter.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';
import 'models/memory_embedding.dart';

/// Main API for interacting with the universal agent memory graph.
/// Provides CRUD, semantic search, embeddings integration, and explainability for LLMs/agents.
class MemoryGraph {
  final Isar isar;
  final EmbeddingsAdapter embeddingsAdapter;
  late final dvdb.Collection _vectorCollection;

  /// Create a MemoryGraph with the given [Isar] instance and [EmbeddingsAdapter].
  MemoryGraph(this.isar, {required this.embeddingsAdapter}) {
    _vectorCollection = dvdb.DVDB().collection('default');
  }

  /// Initializes the vector index with existing nodes from Isar.
  /// This should be called once when the application starts.
  Future<void> initialize() async {
    final allNodes = await isar.memoryNodes.where().findAll();
    
    for (final node in allNodes) {
      if (node.embedding != null) {
        // The DVDB example shows addDocument is synchronous.
        _vectorCollection.addDocument(node.id.toString(), node.content, Float64List.fromList(node.embedding!.vector));
      }
    }
  }

  /// Stores a new memory node with an embedding generated from [content].
  ///
  /// [type], [metadata] and other fields are optional. Embedding is generated via the adapter (Gemini).
  Future<int> storeNodeWithEmbedding({
    required String content,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    final vector = await embeddingsAdapter.embed(content);
    final embedding = MemoryEmbedding(
      vector: vector,
      provider: embeddingsAdapter.providerName,
      dimension: vector.length,
    );
    final node = MemoryNode(
      content: content,
      type: type,
      embedding: embedding,
      metadata: metadata,
    );
    return await storeNode(node);
  }

  /// Store a new memory node (manual, with or without embedding).
  /// Also adds the node's embedding to the vector index if it exists.
  Future<int> storeNode(MemoryNode node) async {
    final nodeId = await isar.writeTxn(() => isar.memoryNodes.put(node));
    // Also add to the vector index
    if (node.embedding != null) {
      _vectorCollection.addDocument(nodeId.toString(), node.content, Float64List.fromList(node.embedding!.vector));
    }
    return nodeId;
  }

  /// Get a memory node by ID.
  Future<MemoryNode?> getNode(int id) async {
    return await isar.memoryNodes.get(id);
  }

  /// Delete a memory node by ID from both Isar and the vector index.
  Future<bool> deleteNode(int id) async {
    // Remove from vector index first
    _vectorCollection.removeDocument(id.toString());
    // Then remove from Isar
    return await isar.writeTxn(() => isar.memoryNodes.delete(id));
  }

  /// Store a new edge (relation) between nodes.
  Future<int> storeEdge(MemoryEdge edge) async {
    return await isar.writeTxn(() => isar.memoryEdges.put(edge));
  }

  /// Get all edges for a node (incoming or outgoing).
  Future<List<MemoryEdge>> getEdgesForNode(int nodeId) async {
    final outgoing = await isar.memoryEdges.filter().fromNodeIdEqualTo(nodeId).findAll();
    final incoming = await isar.memoryEdges.filter().toNodeIdEqualTo(nodeId).findAll();
    return [...outgoing, ...incoming];
  }

  /// Semantic search for nodes using the efficient HNSW index from DVDB.
  /// Returns topK most similar nodes, including distance.
  // TODO: The dvdb package is currently broken (internal typo `searchineSimilarity` instead of `cosineSimilarity`).
  // This method will fail until dvdb is fixed or replaced. Tests are skipped.
  Future<List<({MemoryNode node, double distance, String provider})>> semanticSearch(
    List<double> queryEmbedding, {
    int topK = 5,
  }) async {
    // Ensure the query embedding has the same dimension as the collection.
    if (queryEmbedding.length != embeddingsAdapter.dimension) {
      return [];
    }
        final searchResults = _vectorCollection.search(Float64List.fromList(queryEmbedding), numResults: topK);

    if (searchResults.isEmpty) return [];

    final nodeIds = searchResults.map((r) => int.parse(r.id)).toList();
    final nodes = await isar.memoryNodes.getAll(nodeIds);

    final results = <({MemoryNode node, double distance, String provider})>[];
    for (var i = 0; i < searchResults.length; i++) {
      final node = nodes[i];
      if (node != null) {
        results.add((
          node: node,
          distance: searchResults[i].score,
          provider: node.embedding?.provider ?? 'unknown',
        ));
      }
    }
    return results;
  }

  /// Helper: L2 distance between two vectors.
  double _l2(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;
    double sum = 0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return sum;
  }

  /// Explain why a node was retrieved, including:
  /// - Semantic distance and embedding provider (if queryEmbedding provided)
  /// - Path(s) from root nodes (BFS up to [maxDepth])
  /// - Activation (recency, frequency, degree)
  /// - Simple logging for traceability
  Future<String> explainRecall(
    int nodeId, {
    List<double>? queryEmbedding,
    int maxDepth = 2,
    bool log = true,
  }) async {
    final node = await getNode(nodeId);
    if (node == null) return 'Node not found.';
    final edges = await getEdgesForNode(nodeId);
    final now = DateTime.now().toUtc();
    StringBuffer explain = StringBuffer();
    explain.write('Node ${node.id} recalled; ${edges.length} relations.');
    // Semantic similarity
    if (queryEmbedding != null && node.embedding != null) {
      final dist = _l2(node.embedding!.vector, queryEmbedding);
      explain.write(' Semantic distance: ${dist.toStringAsFixed(3)} (provider: ${node.embedding!.provider}).');
    }
    // Activation info
    if (node.degree != null) {
      explain.write(' Activation(recency: ');
      if (node.degree!.lastAccessed != null) {
        final ago = now.difference(node.degree!.lastAccessed!).inSeconds;
        explain.write('${ago}s ago');
      } else {
        explain.write('never');
      }
      explain.write(', freq: ${node.degree!.frequency}, imp: ${node.degree!.importance}).');
    }
    // Path tracing (BFS up to maxDepth)
    final paths = await _findPathsToNode(nodeId, maxDepth: maxDepth);
    if (paths.isNotEmpty) {
      explain.write(' Path(s) from roots (depth ≤ $maxDepth): ');
      for (final path in paths) {
        explain.write(path.join(' → '));
        explain.write('; ');
      }
    }
    if (log) {
      // Simple print log for traceability
      print('[ExplainRecall] Node $nodeId: ${explain.toString()}');
    }
    return explain.toString();
  }

  /// Finds paths from root nodes to [targetId] up to [maxDepth] (BFS).
  /// Returns a list of node id paths.
  Future<List<List<int>>> _findPathsToNode(int targetId, {int maxDepth = 2}) async {
    List<List<int>> paths = [];
    
    // Find all root nodes (nodes with no incoming edges)
    final allNodes = await isar.memoryNodes.where().findAll();
    final allEdges = await isar.memoryEdges.where().findAll();
    final nodeIds = allNodes.map((n) => n.id).toSet();
    final toIds = allEdges.map((e) => e.toNodeId).toSet();
    final rootIds = nodeIds.difference(toIds);
    // BFS from roots to targetId
    for (final root in rootIds) {
      final queue = <List<int>>[[root]];
      while (queue.isNotEmpty) {
        final path = queue.removeAt(0);
        final last = path.last;
        if (path.length > maxDepth + 1) continue;
        if (last == targetId) {
          paths.add(path);
          continue;
        }
        final outgoing = allEdges.where((e) => e.fromNodeId == last).map((e) => e.toNodeId);
        for (final next in outgoing) {
          if (!path.contains(next)) {
            queue.add([...path, next]);
          }
        }
      }
    }
    return paths;
  }
}
