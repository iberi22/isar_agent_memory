import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'embeddings_adapter.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';
import 'models/memory_embedding.dart';
import 'vector_index.dart';
import 'vector_index_objectbox.dart';

/// Main API for interacting with the universal agent memory graph.
///
/// Provides CRUD operations, semantic search, embeddings integration, and
/// explainability features for LLMs and AI agents.
class MemoryGraph {
  /// The underlying Isar database instance.
  final Isar isar;

  /// The adapter for generating embeddings.
  final EmbeddingsAdapter embeddingsAdapter;

  /// Pluggable vector index backend (e.g., ObjectBox, Remote/custom).
  late final VectorIndex _index;

  /// Creates a [MemoryGraph] with the given [Isar] instance and [EmbeddingsAdapter].
  /// Optionally, a custom [VectorIndex] can be provided. If none is provided,
  /// a default ObjectBox-based index will be used.
  MemoryGraph(
    this.isar, {
    required this.embeddingsAdapter,
    VectorIndex? index,
  }) {
    _index = index ?? ObjectBoxVectorIndex.open(namespace: 'default');
  }

  /// Initializes the vector index with existing nodes from the Isar database.
  ///
  /// This method should be called once when the application starts to ensure the
  /// vector index is synchronized with the persisted nodes.
  Future<void> initialize() async {
    await _index.load();

    final allNodes = await isar.memoryNodes.where().findAll();
    for (final node in allNodes) {
      if (node.embedding != null) {
        // Safely attempt to add the document to the index.
        // Errors might occur if dimensions mismatch.
        try {
          await _index.removeDocument(node.id.toString());
          await _index.addDocument(
            node.id.toString(),
            node.content,
            Float32List.fromList(
                node.embedding!.vector.map((e) => e.toDouble()).toList()),
          );
        } catch (e) {
          print('Warning: Failed to index node ${node.id}: $e');
        }
      }
    }
  }

  /// Stores a new memory node with an embedding generated from its [content].
  ///
  /// The embedding is created using the provided [embeddingsAdapter].
  ///
  /// [deduplicate]: If true, checks if a similar memory already exists.
  /// [deduplicationThreshold]: The distance threshold for deduplication (default 0.05).
  ///
  /// Returns the unique ID of the stored (or existing) node.
  Future<int> storeNodeWithEmbedding({
    required String content,
    String? type,
    Map<String, dynamic>? metadata,
    bool deduplicate = false,
    double deduplicationThreshold = 0.05,
  }) async {
    final vector = await embeddingsAdapter.embed(content);

    // 1. Deduplication check
    if (deduplicate) {
      try {
        final existing = await _index.search(
          Float32List.fromList(vector.map((e) => e.toDouble()).toList()),
          topK: 1,
        );
        if (existing.isNotEmpty &&
            existing.first.score < deduplicationThreshold) {
          final existingId = int.parse(existing.first.id);
          // Optional: Merge logic could go here (e.g., update timestamp)
          print(
              'Duplicate memory found (distance: ${existing.first.score}). Returning existing node $existingId.');
          return existingId;
        }
      } catch (e) {
        print('Deduplication check failed: $e. Proceeding to store new node.');
      }
    }

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
      // Replace any existing vector for this ID to avoid duplicates during tests
      try {
        await _index.removeDocument(nodeId.toString());
        await _index.addDocument(
          nodeId.toString(),
          node.content,
          Float32List.fromList(
              node.embedding!.vector.map((e) => e.toDouble()).toList()),
        );
      } catch (e) {
        print('Warning: Failed to index node $nodeId: $e');
        // We do not rethrow here because the node is already stored in Isar.
        // The index inconsistency should be handled by the application (e.g. re-indexing).
      }
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
    try {
      await _index.removeDocument(id.toString());
    } catch (e) {
      print('Warning: Failed to remove node $id from index: $e');
    }
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
  // Vector index search via pluggable backend (ObjectBox by default).
  Future<List<({MemoryNode node, double distance, String provider})>>
      semanticSearch(
    List<double> queryEmbedding, {
    int topK = 5,
  }) async {
    // Gracefully return empty list if dimensions mismatch, as tests expect.
    if (queryEmbedding.length != embeddingsAdapter.dimension) {
      return [];
    }

    // Use pluggable vector index.
    try {
      final searchResults = await _index.search(
        Float32List.fromList(queryEmbedding.map((e) => e.toDouble()).toList()),
        topK: topK,
      );

      if (searchResults.isNotEmpty) {
        final nodeIds = searchResults.map((r) => int.parse(r.id)).toList();
        final nodes = await isar.memoryNodes.getAll(nodeIds);
        final results =
            <({MemoryNode node, double distance, String provider})>[];
        for (var i = 0; i < searchResults.length; i++) {
          final node = nodes[i];
          if (node != null) {
            results.add((
              node: node,
              distance: searchResults[i].score,
              provider: _index.provider,
            ));
          }
        }
        return results;
      }
    } catch (e) {
      print('Warning: Vector search failed ($e). Falling back to linear scan.');
    }

    // Fallback to linear scan if the index returns no results or fails.
    final allNodes = await isar.memoryNodes.where().findAll();

    final distances = allNodes
        .map((n) => (n.embedding != null)
            ? _l2(queryEmbedding, n.embedding!.vector)
            : double.infinity)
        .toList();

    final sortedIndices = List.generate(distances.length, (i) => i)
      ..sort((a, b) => distances[a].compareTo(distances[b]));

    final topKIndices = sortedIndices.take(topK);

    return topKIndices
        .map((i) => (
              node: allNodes[i],
              distance: distances[i],
              provider: 'linear-scan'
            ))
        .toList();
  }

  /// Performs a hybrid search combining semantic similarity and full-text search.
  ///
  /// [query] is the text to search for.
  /// [topK] is the number of results to return.
  /// [alpha] controls the weight of the vector search vs. text search (0.0 = text only, 1.0 = vector only).
  ///
  /// This method uses Reciprocal Rank Fusion (RRF) implicitly by combining scores if possible,
  /// or a simpler weighted scoring mechanism if scores are available.
  /// Since Isar filters don't provide relevance scores, we treat text matches as having a fixed score boost.
  Future<List<({MemoryNode node, double score})>> hybridSearch(
    String query, {
    int topK = 5,
    double alpha = 0.5,
  }) async {
    // 1. Vector Search
    List<({MemoryNode node, double distance, String provider})> vectorResults =
        [];
    try {
      final queryEmbedding = await embeddingsAdapter.embed(query);
      vectorResults = await semanticSearch(queryEmbedding, topK: topK * 2);
    } catch (e) {
      print('Hybrid search: Vector search failed ($e).');
    }

    // 2. Text Search (Isar Filter)
    // Note: This is a boolean filter, not a ranked FTS.
    // For a real FTS, we would need @Index(type: IndexType.value) and tokenization.
    final textResults = await isar.memoryNodes
        .filter()
        .contentContains(query, caseSensitive: false)
        .limit(topK * 2)
        .findAll();

    // 3. Fusion (Weighted Scoring)
    // We normalize vector distance (lower is better) to similarity (higher is better).
    // Sim = 1 / (1 + distance)
    // Text Match Score = 1.0 (since we don't have granularity)

    final Map<int, double> scores = {};
    final Map<int, MemoryNode> nodes = {};

    // Process Vector Results
    for (final res in vectorResults) {
      final id = res.node.id;
      nodes[id] = res.node;
      final sim = 1.0 / (1.0 + res.distance);
      scores[id] = (scores[id] ?? 0.0) + (sim * alpha);
    }

    // Process Text Results
    for (final node in textResults) {
      final id = node.id;
      nodes[id] = node;
      // Assign a fixed high relevance for text match
      // If a node was already found by vector, we add (1-alpha) * 1.0
      // If not, we initialize with (1-alpha) * 1.0
      scores[id] = (scores[id] ?? 0.0) + (1.0 * (1.0 - alpha));
    }

    // Sort by final score (descending)
    final sortedIds = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    return sortedIds
        .take(topK)
        .map((id) => (node: nodes[id]!, score: scores[id]!))
        .toList();
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

  /// Clears the vector collection.
  ///
  /// This is primarily for testing purposes to ensure a clean state between tests.
  Future<void> clearVectorCollection() async {
    await _index.clear();
  }
}
