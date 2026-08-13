/// Query router for agentic retrieval — classifies queries and selects the
/// optimal retrieval strategy based on intent, complexity, and confidence.
///
/// Inspired by modular RAG routing patterns (2025-2026):
/// - Factoid / lookup queries → vector search
/// - Multi-part / complex queries → hybrid search + decomposition
/// - Temporal queries ("what happened yesterday") → temporal filter
/// - Relationship queries ("how is X related to Y") → graph traversal
/// - Summary / overview queries → HiRAG multi-hop
///
/// ## Usage
///
/// ```dart
/// final router = QueryRouter(graph: graph, embeddings: adapter);
/// final plan = await router.classify('what did the user do last week?');
/// // plan.strategy == QueryStrategy.temporal
/// final results = await router.execute(plan);
/// ```
library;

import 'dart:math' as math;
import 'memory_graph.dart';
import 'embeddings_adapter.dart';
import 'pipeline_hooks.dart';
import 'hierarchical_graph.dart';
import 'models/memory_node.dart';

// ---------------------------------------------------------------------------
// Query classification
// ---------------------------------------------------------------------------

/// The retrieval strategy selected by the router.
enum QueryStrategy {
  /// Fast single-hop vector search — for factual/lookup queries.
  vector,

  /// Combined vector + BM25 — for precise term matching.
  hybrid,

  /// Temporal filter — for time-bounded queries.
  temporal,

  /// Graph traversal — for relationship/entity queries.
  graph,

  /// HiRAG multi-hop — for summary/overview queries.
  hierarchical,

  /// Parallel multi-strategy with fusion — for complex queries.
  multiStrategy,

  /// Query too vague — ask for clarification.
  clarify,
}

/// A routing decision produced by [QueryRouter].
class RoutingPlan {
  final QueryStrategy strategy;
  final String query;
  final List<String>? subQueries;
  final double confidence;
  final String reasoning;

  RoutingPlan({
    required this.strategy,
    required this.query,
    this.subQueries,
    required this.confidence,
    required this.reasoning,
  });
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

/// Rule-based query router that classifies queries without an LLM call.
///
/// Uses lightweight heuristics: temporal keywords, question words, length,
/// entity mentions, punctuation, etc.
class QueryRouter {
  final MemoryGraph graph;
  final EmbeddingsAdapter embeddings;

  // Confidence thresholds
  final double highConfidenceThreshold = 0.8;
  final double lowConfidenceThreshold = 0.4;

  QueryRouter({
    required this.graph,
    required this.embeddings,
  });

  /// Classify a raw query into a [RoutingPlan].
  RoutingPlan classify(String query) {
    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();

    // --- Detect clarification-needed queries ---
    if (trimmed.length < 5 && !_looksLikeEntity(trimmed)) {
      return RoutingPlan(
        strategy: QueryStrategy.clarify,
        query: trimmed,
        confidence: 0.3,
        reasoning: 'Query too short to route with confidence',
      );
    }

    // --- Detect temporal queries ---
    if (_hasTemporalIntent(lower)) {
      return RoutingPlan(
        strategy: QueryStrategy.temporal,
        query: trimmed,
        confidence: 0.85,
        reasoning: 'Temporal keywords detected',
      );
    }

    // --- Detect relationship / graph queries ---
    if (_hasRelationshipIntent(lower)) {
      return RoutingPlan(
        strategy: QueryStrategy.graph,
        query: trimmed,
        confidence: 0.8,
        reasoning: 'Relationship/graph keywords detected',
      );
    }

    // --- Detect summary / overview queries ---
    if (_hasSummaryIntent(lower)) {
      return RoutingPlan(
        strategy: QueryStrategy.hierarchical,
        query: trimmed,
        confidence: 0.75,
        reasoning: 'Summary/overview intent detected',
      );
    }

    // --- Detect multi-part queries ---
    if (_isMultiPart(lower)) {
      final parts = _splitParts(trimmed);
      return RoutingPlan(
        strategy: QueryStrategy.multiStrategy,
        query: trimmed,
        subQueries: parts,
        confidence: 0.7,
        reasoning: 'Multi-part query detected — parallel retrieval',
      );
    }

    // --- Detect precise term queries ---
    if (_hasPreciseTerms(lower)) {
      return RoutingPlan(
        strategy: QueryStrategy.hybrid,
        query: trimmed,
        confidence: 0.75,
        reasoning: 'Precise terms detected — hybrid search for recall',
      );
    }

    // --- Default: vector search ---
    return RoutingPlan(
      strategy: QueryStrategy.vector,
      query: trimmed,
      confidence: 0.65,
      reasoning: 'Default routing — general semantic query',
    );
  }

  /// Execute a [RoutingPlan] and return the best matching nodes.
  Future<List<RetrievedNode>> execute(RoutingPlan plan) async {
    switch (plan.strategy) {
      case QueryStrategy.vector:
        return _vectorSearch(plan.query, topK: 5);

      case QueryStrategy.hybrid:
        return _hybridSearch(plan.query, topK: 5);

      case QueryStrategy.temporal:
        return _temporalSearch(plan.query, topK: 5);

      case QueryStrategy.graph:
        return _graphSearch(plan.query, topK: 5);

      case QueryStrategy.hierarchical:
        return _hierarchicalSearch(plan.query, topK: 5);

      case QueryStrategy.multiStrategy:
        return _multiStrategySearch(plan, topK: 5);

      case QueryStrategy.clarify:
        return []; // caller should ask for clarification
    }
  }

  /// Full agentic pipeline: classify → execute → (optionally) iterate.
  Future<MemoryPipelineResult> runPipeline(
    String query, {
    MemoryPipeline? pipeline,
    String? sessionId,
  }) async {
    final plan = classify(query);

    // If a custom pipeline is provided, use it instead of the direct router
    if (pipeline != null) {
      return pipeline.run(query, sessionId: sessionId);
    }

    final stopwatch = Stopwatch()..start();
    final results = await execute(plan);
    stopwatch.stop();

    final context = PipelineContext(query: query, sessionId: sessionId)
      ..retrievedNodes = results
      ..metadata['strategy'] = plan.strategy.name
      ..metadata['confidence'] = plan.confidence;

    return MemoryPipelineResult(
      results: results,
      elapsed: stopwatch.elapsed,
      context: context,
    );
  }

  // -----------------------------------------------------------------------
  // Internal search implementations
  // -----------------------------------------------------------------------

  Future<List<RetrievedNode>> _vectorSearch(String query,
      {int topK = 5}) async {
    final emb = await embeddings.embed(query);
    final results = await graph.semanticSearch(emb, topK: topK);
    return results
        .map((r) => RetrievedNode(
              node: r.node,
              score: 1.0 - r.distance,
              source: 'vector',
              explanation: 'distance=${r.distance.toStringAsFixed(3)}',
            ))
        .toList();
  }

  Future<List<RetrievedNode>> _hybridSearch(String query,
      {int topK = 5}) async {
    final results = await graph.hybridSearch(query, topK: topK);
    return results
        .map((r) => RetrievedNode(
              node: r.node,
              score: r.score,
              source: 'hybrid',
              explanation: 'score=${r.score.toStringAsFixed(3)}',
            ))
        .toList();
  }

  Future<List<RetrievedNode>> _temporalSearch(String query,
      {int topK = 5}) async {
    // Extract time range from query (simple heuristics)
    final now = DateTime.now();
    DateTime? since;
    final lower = query.toLowerCase();

    if (lower.contains('yesterday')) {
      since = now.subtract(const Duration(days: 1));
    } else if (lower.contains('last week')) {
      since = now.subtract(const Duration(days: 7));
    } else if (lower.contains('last month')) {
      since = now.subtract(const Duration(days: 30));
    } else if (lower.contains('today')) {
      since = now.subtract(const Duration(days: 1));
    }

    // Fallback: vector search if no temporal filter or no results
    final emb = await embeddings.embed(query);
    var results = await graph.semanticSearch(emb, topK: topK * 3);

    if (since != null) {
      final cutoff = since;
      results = results.where((r) {
        return (r.node.createdAt?.isAfter(cutoff) ?? false);
      }).toList();
    }

    return results
        .take(topK)
        .map((r) => RetrievedNode(
              node: r.node,
              score: 1.0 - r.distance,
              source: 'temporal',
              explanation: since != null
                  ? 'filtered since ${since.toIso8601String()}'
                  : 'vector search (no time filter)',
            ))
        .toList();
  }

  Future<List<RetrievedNode>> _graphSearch(String query, {int topK = 5}) async {
    // Extract potential entity mentions and do graph traversal
    final emb = await embeddings.embed(query);
    final results = await graph.semanticSearch(emb, topK: topK);

    final enriched = <RetrievedNode>[];
    for (final r in results) {
      final edges = await graph.getEdgesForNode(r.node.id);
      final explanation = edges.isNotEmpty
          ? '${edges.length} relations: ${edges.take(3).map((e) => '${e.relation}(${e.fromNodeId}→${e.toNodeId})').join(', ')}'
          : 'no relations found';

      enriched.add(RetrievedNode(
        node: r.node,
        score: 1.0 - r.distance,
        source: 'graph',
        explanation: explanation,
      ));
    }
    return enriched;
  }

  Future<List<RetrievedNode>> _hierarchicalSearch(String query,
      {int topK = 5}) async {
    final emb = await embeddings.embed(query);
    // Multi-hop search via HiRAG
    final results = await graph.multiHopSearch(
      queryEmbedding: emb,
      maxHops: 2,
      topK: topK,
    );
    return results.map((r) {
      final contextSummary = r.context.isNotEmpty
          ? 'parent nodes: ${r.context.map((n) => n.id).join(', ')}'
          : 'no hierarchical context';
      return RetrievedNode(
        node: r.node,
        score: 1.0,
        source: 'hierarchical',
        explanation: contextSummary,
      );
    }).toList();
  }

  Future<List<RetrievedNode>> _multiStrategySearch(RoutingPlan plan,
      {int topK = 5}) async {
    // Run vector + hybrid + temporal in parallel, then fuse
    final futures = <Future<List<RetrievedNode>>>[
      _vectorSearch(plan.query, topK: topK),
      _hybridSearch(plan.query, topK: topK),
    ];

    if (_hasTemporalIntent(plan.query.toLowerCase())) {
      futures.add(_temporalSearch(plan.query, topK: topK));
    }

    final results = await Future.wait(futures);
    final fused = <int, RetrievedNode>{};
    for (final batch in results) {
      for (final r in batch) {
        final id = r.node.id;
        if (fused.containsKey(id)) {
          // Boost score for nodes found by multiple strategies
          fused[id] = RetrievedNode(
            node: r.node,
            score: math.min(1.0, fused[id]!.score + r.score * 0.3),
            source: 'fused',
            explanation: '${fused[id]!.explanation}; ${r.explanation}',
          );
        } else {
          fused[id] = r;
        }
      }
    }

    final sorted = fused.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(topK).toList();
  }

  // -----------------------------------------------------------------------
  // Heuristic helpers
  // -----------------------------------------------------------------------

  static final _temporalWords = RegExp(
    r'\b(yesterday|today|last\s+\w+|this\s+\w+|previous|recent|oldest|newest|ago|since|during|at\s+\d|on\s+\d)\b',
    caseSensitive: false,
  );

  static final _relationshipWords = RegExp(
    r'\b(relation|connect|link|associate|related|how.*related|between|path|graph|network|connected|linked|edge|traverse)\b',
    caseSensitive: false,
  );

  static final _summaryWords = RegExp(
    r'\b(summarize|summary|overview|recap|brief|what.*about|tell.*about|explain|describe|outline|digest)\b',
    caseSensitive: false,
  );

  static final _preciseTerms = RegExp(
    r'\b(code|id|exact|specific|version|v\d+|protocol|standard|format|regex|pattern)\b',
    caseSensitive: false,
  );

  static final _conjunctionSplit = RegExp(
    r'\b(and|or|also|plus|with|alongside)\b',
    caseSensitive: false,
  );

  static bool _hasTemporalIntent(String q) => _temporalWords.hasMatch(q);
  static bool _hasRelationshipIntent(String q) =>
      _relationshipWords.hasMatch(q);
  static bool _hasSummaryIntent(String q) => _summaryWords.hasMatch(q);
  static bool _hasPreciseTerms(String q) => _preciseTerms.hasMatch(q);

  static bool _isMultiPart(String q) {
    // Multiple questions or conjunction splits
    final questionMarks = '?'.allMatches(q).length;
    if (questionMarks > 1) return true;
    // Multiple conjunction-split clauses
    return _conjunctionSplit.allMatches(q).length > 1;
  }

  static bool _looksLikeEntity(String q) {
    // Short strings starting with uppercase or containing numbers
    return RegExp(r'^[A-Z]').hasMatch(q) || RegExp(r'\d').hasMatch(q);
  }

  static List<String> _splitParts(String q) {
    // Simple split on conjunctions and question marks
    final parts = q
        .split(RegExp(r'[?]|(?:\s+(?:and|or|also|plus|with)\s+)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts;
  }
}
