/// Session-scoped memory context for multi-tenant isolation.
///
/// Wraps a [MemoryGraph] and automatically scopes all operations to a
/// session/user namespace. Each tenant's data is isolated via metadata
/// filtering — no separate database per session needed.
///
/// ## Usage
///
/// ```dart
/// final session = SessionContext(
///   graph: memoryGraph,
///   sessionId: 'user-123',
/// );
///
/// // All operations are automatically scoped
/// await session.store('User prefers dark mode');
/// final memories = await session.search('preferences');
/// ```
library;

import 'memory_graph.dart';
import 'models/memory_node.dart';
import 'models/memory_edge.dart';

/// Scoped memory context for a single session or user.
///
/// All stored nodes get tagged with [sessionId] and/or [userId] in their
/// metadata. Retrieval automatically filters by these tags so one session
/// never sees another session's data.
class SessionContext {
  final MemoryGraph graph;

  /// Unique identifier for this session (e.g., conversation ID).
  final String? sessionId;

  /// Unique identifier for the user/agent (e.g., user ID, agent ID).
  final String? userId;

  /// The metadata key used to store [sessionId].
  static const String kSessionKey = '_session_id';

  /// The metadata key used to store [userId].
  static const String kUserKey = '_user_id';

  SessionContext({
    required this.graph,
    this.sessionId,
    this.userId,
  });

  // -----------------------------------------------------------------------
  // Write operations (auto-scoped)
  // -----------------------------------------------------------------------

  /// Store a memory node scoped to this session.
  Future<int> store(String content, {String? type}) async {
    return graph.storeNodeWithEmbedding(
      content: content,
      type: type,
      metadata: _scopeMetadata(),
    );
  }

  /// Store a node with full control over metadata.
  Future<int> storeNode(MemoryNode node) async {
    node.metadata ??= {};
    node.metadata!.addAll(_scopeMetadata());
    return graph.storeNode(node);
  }

  /// Store an edge scoped to this session's nodes.
  Future<int> storeEdge(MemoryEdge edge) async {
    return graph.storeEdge(edge);
  }

  // -----------------------------------------------------------------------
  // Read operations (auto-filtered)
  // -----------------------------------------------------------------------

  /// Retrieve all nodes in this session.
  Future<List<MemoryNode>> getAll() async {
    return _filter(graph.isar.memoryNodes.where().findAll());
  }

  /// Semantic search scoped to this session.
  Future<List<({MemoryNode node, double distance, String provider})>>
      semanticSearch(
    List<double> queryEmbedding, {
    int topK = 5,
    int? layer,
  }) async {
    final results = await graph.semanticSearch(
      queryEmbedding,
      topK: topK * 3, // fetch extra, filter by session
      layer: layer,
    );
    return results.where((r) => _matchesScope(r.node)).take(topK).toList();
  }

  /// Hybrid search scoped to this session.
  Future<List<({MemoryNode node, double score})>> hybridSearch(
    String query, {
    int topK = 5,
    double alpha = 0.5,
  }) async {
    final results = await graph.hybridSearch(
      query,
      topK: topK * 3,
      alpha: alpha,
    );
    return results.where((r) => _matchesScope(r.node)).take(topK).toList();
  }

  /// Delete all nodes in this session.
  Future<int> clear() async {
    final nodes = await getAll();
    for (final n in nodes) {
      await graph.deleteNode(n.id);
    }
    return nodes.length;
  }

  /// Number of nodes in this session.
  Future<int> count() async {
    final nodes = await getAll();
    return nodes.length;
  }

  // -----------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------

  Map<String, dynamic> _scopeMetadata() {
    final meta = <String, dynamic>{};
    if (sessionId != null) meta[kSessionKey] = sessionId;
    if (userId != null) meta[kUserKey] = userId;
    return meta;
  }

  bool _matchesScope(MemoryNode node) {
    if (sessionId != null &&
        node.metadata?[kSessionKey] != sessionId) {
      return false;
    }
    if (userId != null &&
        node.metadata?[kUserKey] != userId) {
      return false;
    }
    return true;
  }

  Future<List<MemoryNode>> _filter(Future<List<MemoryNode>> future) async {
    final nodes = await future;
    return nodes.where(_matchesScope).toList();
  }
}
