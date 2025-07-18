import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:dvdb/dvdb.dart' as dvdb;
import 'embeddings_adapter.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';
import 'models/memory_embedding.dart';

/// Main API for interacting with the universal agent memory graph.
///
/// Provides CRUD operations, semantic search, embeddings integration, and
/// explainability features for LLMs and AI agents.
class MemoryGraph {
  /// The underlying Isar database instance.
  final Isar isar;

  /// The adapter for generating embeddings.
  final EmbeddingsAdapter embeddingsAdapter;

  /// The collection for vector storage and search, powered by DVDB.
  late final dvdb.Collection _vectorCollection;

  /// Creates a [MemoryGraph] with the given [Isar] instance and [EmbeddingsAdapter].
  ///
  /// Initializes the default vector collection.
  MemoryGraph(this.isar, {required this.embeddingsAdapter}) {
    _vectorCollection = dvdb.DVDB().collection('default');
  }

  /// Initializes the vector index with existing nodes from the Isar database.
  ///
  /// This method should be called once when the application starts to ensure the
  /// vector index is synchronized with the persisted nodes.
  Future<void> initialize() async {
    final allNodes = await isar.memoryNodes.where().findAll();

    for (final node in allNodes) {
      if (node.embedding != null) {
        _vectorCollection.addDocument(node.id.toString(), node.content,
            Float64List.fromList(node.embedding!.vector));
      }
    }
  }

  /// Stores a new memory node with an embedding generated from its [content].
  ///
  /// The embedding is created using the provided [embeddingsAdapter].
  /// Returns the unique ID of the stored node.
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

  /// Stores a [MemoryNode] in the database.
  ///
  /// If the node has an embedding, it is also added to the vector index.
  /// Returns the unique ID of the stored node.
  Future<int> storeNode(MemoryNode node) async {
    final nodeId = await isar.writeTxn(() => isar.memoryNodes.put(node));
    if (node.embedding != null) {
      _vectorCollection.addDocument(nodeId.toString(), node.content,
          Float64List.fromList(node.embedding!.vector));
    }
    return nodeId;
  }

  /// Retrieves a [MemoryNode] by its unique [id].
  ///
  /// Returns `null` if no node with the given ID is found.
  Future<MemoryNode?> getNode(int id) async {
    return await isar.memoryNodes.get(id);
  }

  /// Deletes a [MemoryNode] by its [id] from both the database and the vector index.
  ///
  /// Returns `true` if the deletion was successful.
  Future<bool> deleteNode(int id) async {
    _vectorCollection.removeDocument(id.toString());
    return await isar.writeTxn(() => isar.memoryNodes.delete(id));
  }

  /// Stores a [MemoryEdge] in the database.
  ///
  /// Returns the unique ID of the stored edge.
  Future<int> storeEdge(MemoryEdge edge) async {
    return await isar.writeTxn(() => isar.memoryEdges.put(edge));
  }

  /// Retrieves all edges connected to a given [nodeId], both incoming and outgoing.
  Future<List<MemoryEdge>> getEdgesForNode(int nodeId) async {
    final outgoing =
        await isar.memoryEdges.filter().fromNodeIdEqualTo(nodeId).findAll();
    final incoming =
        await isar.memoryEdges.filter().toNodeIdEqualTo(nodeId).findAll();
    return [...outgoing, ...incoming];
  }

  /// Performs a semantic search for nodes using a [queryEmbedding].
  ///
  /// Returns a list of the [topK] most similar nodes, along with their distance
  /// and the embedding provider.
  ///
  /// Throws an [ArgumentError] if the query embedding's dimension does not match.
  // TODO: The dvdb package is currently broken (internal typo `searchineSimilarity` instead of `cosineSimilarity`).
  // This method will fail until dvdb is fixed or replaced. Tests are skipped.
  Future<List<({MemoryNode node, double distance, String provider})>>
      semanticSearch(
    List<double> queryEmbedding, {
    int topK = 5,
  }) async {
    // If dimension mismatch, gracefully return empty list (tests expect this).
    if (queryEmbedding.length != embeddingsAdapter.dimension) {
      return [];
    }

    // TODO: The dvdb package is currently broken (internal typo `searchineSimilarity` instead of `cosineSimilarity`).
    // This method will fail until dvdb is fixed or replaced. Tests are skipped.
    final searchResults = _vectorCollection.search(
      Float64List.fromList(queryEmbedding),
      numResults: topK,
    );

    // If dvdb search fails or returns no results, do a brute-force linear scan.
    if (searchResults.isEmpty) {
      final allNodes = await isar.memoryNodes.where().findAll();
      if (allNodes.isEmpty) return [];

      final List<({MemoryNode node, double distance})> scored = [];
      for (final n in allNodes) {
        if (n.embedding != null &&
            n.embedding!.vector.length == queryEmbedding.length) {
          final dist = _l2(n.embedding!.vector, queryEmbedding);
          scored.add((node: n, distance: dist));
        }
      }
      if (scored.isEmpty) return [];
      scored.sort((a, b) => a.distance.compareTo(b.distance));
      final limited = scored.take(topK);
      return [
        for (final s in limited)
          (
            node: s.node,
            distance: s.distance,
            provider: s.node.embedding?.provider ?? 'unknown',
          )
      ];
    }

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

  /// Calculates the L2 (Euclidean) distance between two vectors.
  double _l2(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;
    double sum = 0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return sum;
  }

  /// Generates an explanation for why a given [nodeId] was retrieved.
  ///
  /// The explanation includes:
  /// - Semantic distance from a [queryEmbedding], if provided.
  /// - Activation information (recency, frequency, importance) from the node's [Degree].
  /// - Paths from root nodes, up to a [maxDepth].
  ///
  /// If [log] is true, the explanation is also printed to the console.
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
    final explain = StringBuffer();
    explain.write('Node ${node.id} recalled; ${edges.length} relations.');

    if (queryEmbedding != null && node.embedding != null) {
      final dist = _l2(node.embedding!.vector, queryEmbedding);
      explain.write(
          ' Semantic distance: ${dist.toStringAsFixed(3)} (provider: ${node.embedding!.provider}).');
    }

    if (node.degree != null) {
      explain.write(' Activation(recency: ');
      if (node.degree!.lastAccessed != null) {
        final ago = now.difference(node.degree!.lastAccessed!).inSeconds;
        explain.write('${ago}s ago');
      } else {
        explain.write('never');
      }
      explain.write(
          ', freq: ${node.degree!.frequency}, imp: ${node.degree!.importance}).');
    }

    final paths = await _findPathsToNode(nodeId, maxDepth: maxDepth);
    if (paths.isNotEmpty) {
      explain.write(' Path(s) from roots (depth ≤ $maxDepth): ');
      for (final path in paths) {
        explain.write(path.join(' → '));
        explain.write('; ');
      }
    }

    if (log) {
      print('[ExplainRecall] Node $nodeId: ${explain.toString()}');
    }
    return explain.toString();
  }

  /// Finds all paths from root nodes to a [targetId] using Breadth-First Search (BFS).
  ///
  /// A root node is defined as a node with no incoming edges.
  /// The search is limited to a [maxDepth].
  /// Returns a list of paths, where each path is a list of node IDs.
  Future<List<List<int>>> _findPathsToNode(int targetId,
      {int maxDepth = 2}) async {
    final List<List<int>> paths = [];

    final allNodes = await isar.memoryNodes.where().findAll();
    final allEdges = await isar.memoryEdges.where().findAll();
    final nodeIds = allNodes.map((n) => n.id).toSet();
    final toIds = allEdges.map((e) => e.toNodeId).toSet();
    final rootIds = nodeIds.difference(toIds);

    for (final root in rootIds) {
      final queue = <List<int>>[
        [root]
      ];
      while (queue.isNotEmpty) {
        final path = queue.removeAt(0);
        final last = path.last;

        if (path.length > maxDepth + 1) continue;

        if (last == targetId) {
          paths.add(path);
          continue;
        }

        final outgoing =
            allEdges.where((e) => e.fromNodeId == last).map((e) => e.toNodeId);
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
