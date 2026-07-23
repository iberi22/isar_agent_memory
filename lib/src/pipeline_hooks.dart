library;

import 'memory_graph.dart';
import 'embeddings_adapter.dart';
import 'models/memory_node.dart';

/// Generic pipeline hooks for composable RAG pipelines.
///
/// These interfaces allow consumers to plug domain-specific logic into
/// the retrieval pipeline without modifying the core package.
/// Inspired by modular RAG patterns (2025-2026 state-of-the-art).
///
/// ## Usage
///
/// ```dart
/// final pipeline = MemoryPipeline()
///   ..addExpansionHook(myExpander)
///   ..addRetrievalHook(myRetriever);
///
/// final results = await pipeline.run(context);
/// ```

// ---------------------------------------------------------------------------
// Core pipeline types
// ---------------------------------------------------------------------------

/// The shared context object passed through every stage of the pipeline.
///
/// Each hook can read, modify, or augment this context. After all hooks run
/// the final [MemoryPipelineResult] is built from the context.
class PipelineContext {
  /// Original natural-language query from the user/agent.
  final String query;

  /// Optional expanded / rewritten versions of [query].
  /// Populated by [QueryExpansionHook] if configured.
  List<String> expandedQueries;

  /// Raw results from the retrieval stage (before re-ranking, filtering, etc.).
  List<RetrievedNode> retrievedNodes;

  /// Arbitrary metadata that hooks can read and write.
  Map<String, dynamic> metadata;

  /// ID of the session (for session-scoped memory).
  String? sessionId;

  /// ID of the user/agent (for user-scoped memory).
  String? userId;

  PipelineContext({
    required this.query,
    List<String>? expandedQueries,
    List<RetrievedNode>? retrievedNodes,
    Map<String, dynamic>? metadata,
    this.sessionId,
    this.userId,
  })  : expandedQueries = expandedQueries ?? [],
        retrievedNodes = retrievedNodes ?? [],
        metadata = metadata ?? {};
}

/// A single node returned from a retrieval stage.
class RetrievedNode {
  final MemoryNode node;
  final double score;
  final String source; // e.g. 'vector', 'bm25', 'graph', 'temporal'
  String? explanation;

  RetrievedNode({
    required this.node,
    required this.score,
    required this.source,
    this.explanation,
  });
}

/// The final result of a pipeline run.
class MemoryPipelineResult {
  final List<RetrievedNode> results;
  final Duration elapsed;
  final PipelineContext context;

  MemoryPipelineResult({
    required this.results,
    required this.elapsed,
    required this.context,
  });
}

// ---------------------------------------------------------------------------
// Hook interfaces – each stage of a modular RAG pipeline
// ---------------------------------------------------------------------------

/// Hook that runs first — rewrites / decomposes / expands the raw query.
///
/// Examples:
/// - Expand abbreviations ("TA" → "tensión arterial")
/// - Decompose multi-part queries ("symptoms and treatment" → two queries)
/// - Translate to another language
/// - Add synonyms for broader recall
abstract class QueryExpansionHook {
  int get priority;
  Future<void> expand(PipelineContext context);
}

/// Hook that runs retrieval — fetches candidate nodes from one or more sources.
///
/// Implementations may query vector indices, BM25 indexes, knowledge graphs,
/// temporal stores, or external APIs. Results are appended to
/// [PipelineContext.retrievedNodes].
abstract class RetrievalHook {
  int get priority;
  Future<void> retrieve(PipelineContext context);
}

/// Hook that re-ranks / filters / scores the retrieved nodes.
///
/// Runs after all [RetrievalHook]s have collected candidates.
/// May discard low-scoring nodes, apply diversity, boost recency, etc.
abstract class ReRankingHook {
  int get priority;
  Future<void> reRank(PipelineContext context);
}

/// Hook that enriches each result with additional context or explanations.
///
/// Examples:
/// - Attach parent summary nodes (HiRAG context)
/// - Add provenance / citation metadata
/// - Fetch related entities from the knowledge graph
abstract class EnrichmentHook {
  int get priority;
  Future<void> enrich(PipelineContext context);
}

/// Hook that decides whether to stop or continue iterating.
///
/// Enables agentic behaviour: if confidence is high enough, return early;
/// if too low, trigger another retrieval pass.
abstract class EvaluationHook {
  int get priority;
  Future<EvalDecision> evaluate(PipelineContext context);
}

/// Decision returned by [EvaluationHook].
enum EvalDecision {
  /// Accept results and finish.
  accept,

  /// Re-run the pipeline (possibly with a modified query).
  retry,

  /// Ask the user/agent for clarification.
  clarify,
}

// ---------------------------------------------------------------------------
// MemoryPipeline – orchestrator
// ---------------------------------------------------------------------------

/// Composable, hooks-driven RAG pipeline.
///
/// Hooks run in priority order within each stage (lower priority = runs first).
///
/// Default stage order:
///   1. QueryExpansionHook (expand / rewrite the query)
///   2. RetrievalHook       (fetch from one or more backends)
///   3. ReRankingHook       (score, filter, diversify)
///   4. EnrichmentHook      (add context, citations, explanations)
///   5. EvaluationHook      (decide if quality is sufficient)
///
/// You can skip any stage by not registering hooks for it.
class MemoryPipeline {
  final List<QueryExpansionHook> _expansionHooks = [];
  final List<RetrievalHook> _retrievalHooks = [];
  final List<ReRankingHook> _rerankingHooks = [];
  final List<EnrichmentHook> _enrichmentHooks = [];
  final List<EvaluationHook> _evaluationHooks = [];

  /// Maximum number of pipeline iterations (guard against infinite loops).
  int maxIterations = 3;

  /// Register a hook. The hook is placed into the correct stage based on its
  /// interface type. If a hook implements multiple interfaces it must be added
  /// separately for each stage.
  void addExpansionHook(QueryExpansionHook hook) => _expansionHooks.add(hook);
  void addRetrievalHook(RetrievalHook hook) => _retrievalHooks.add(hook);
  void addReRankingHook(ReRankingHook hook) => _rerankingHooks.add(hook);
  void addEnrichmentHook(EnrichmentHook hook) => _enrichmentHooks.add(hook);
  void addEvaluationHook(EvaluationHook hook) => _evaluationHooks.add(hook);

  /// Remove all registered hooks.
  void clearHooks() {
    _expansionHooks.clear();
    _retrievalHooks.clear();
    _rerankingHooks.clear();
    _enrichmentHooks.clear();
    _evaluationHooks.clear();
  }

  /// Run the full pipeline starting from [query].
  Future<MemoryPipelineResult> run(
    String query, {
    String? sessionId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    final context = PipelineContext(
      query: query,
      sessionId: sessionId,
      userId: userId,
      metadata: metadata,
    );

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      // Stage 1 — Query expansion
      _sortByPriority(_expansionHooks);
      for (final hook in _expansionHooks) {
        await hook.expand(context);
      }

      // Stage 2 — Retrieval
      _sortByPriority(_retrievalHooks);
      for (final hook in _retrievalHooks) {
        await hook.retrieve(context);
      }

      // Stage 3 — Re-ranking
      _sortByPriority(_rerankingHooks);
      for (final hook in _rerankingHooks) {
        await hook.reRank(context);
      }

      // Stage 4 — Enrichment
      _sortByPriority(_enrichmentHooks);
      for (final hook in _enrichmentHooks) {
        await hook.enrich(context);
      }

      // Stage 5 — Evaluation
      _sortByPriority(_evaluationHooks);
      EvalDecision decision = EvalDecision.accept;
      for (final hook in _evaluationHooks) {
        final d = await hook.evaluate(context);
        if (d != EvalDecision.accept) {
          decision = d;
          break;
        }
      }

      if (decision == EvalDecision.accept) break;
      if (decision == EvalDecision.clarify) break;
      // retry → continue loop
    }

    stopwatch.stop();
    return MemoryPipelineResult(
      results: context.retrievedNodes,
      elapsed: stopwatch.elapsed,
      context: context,
    );
  }

  void _sortByPriority(List<dynamic> hooks) {
    hooks.sort((a, b) => a.priority.compareTo(b.priority));
  }
}

// ---------------------------------------------------------------------------
// Built-in retrieval hooks (convenience wrappers around MemoryGraph)
// ---------------------------------------------------------------------------

/// Retrieves nodes via vector similarity search.
class VectorRetrievalHook implements RetrievalHook {
  final MemoryGraph graph;
  final EmbeddingsAdapter embeddings;
  final int topK;
  final int? layer;

  @override
  final int priority;

  VectorRetrievalHook({
    required this.graph,
    required this.embeddings,
    this.topK = 5,
    this.layer,
    this.priority = 10,
  });

  @override
  Future<void> retrieve(PipelineContext context) async {
    final query = context.expandedQueries.isNotEmpty
        ? context.expandedQueries.first
        : context.query;
    final queryEmbedding = await embeddings.embed(query);
    final results = await graph.semanticSearch(
      queryEmbedding,
      topK: topK,
      layer: layer,
    );
    for (final r in results) {
      context.retrievedNodes.add(RetrievedNode(
        node: r.node,
        score: 1.0 - r.distance,
        source: 'vector',
        explanation: 'Semantic distance: ${r.distance.toStringAsFixed(3)}',
      ));
    }
  }
}

/// Retrieves nodes via hybrid search (vector + BM25-style text).
class HybridRetrievalHook implements RetrievalHook {
  final MemoryGraph graph;
  final int topK;
  final double alpha;

  @override
  final int priority;

  HybridRetrievalHook({
    required this.graph,
    this.topK = 5,
    this.alpha = 0.5,
    this.priority = 20,
  });

  @override
  Future<void> retrieve(PipelineContext context) async {
    final query = context.expandedQueries.isNotEmpty
        ? context.expandedQueries.first
        : context.query;
    final results = await graph.hybridSearch(query, topK: topK, alpha: alpha);
    for (final r in results) {
      context.retrievedNodes.add(RetrievedNode(
        node: r.node,
        score: r.score,
        source: 'hybrid',
        explanation: 'Hybrid score: ${r.score.toStringAsFixed(3)}',
      ));
    }
  }
}

/// Retrieves context from parent (summary) nodes via HiRAG multi-hop.
class MultiHopEnrichmentHook implements EnrichmentHook {
  final MemoryGraph graph;
  final int maxHops;

  @override
  final int priority;

  MultiHopEnrichmentHook({
    required this.graph,
    this.maxHops = 2,
    this.priority = 10,
  });

  @override
  Future<void> enrich(PipelineContext context) async {
    for (final result in context.retrievedNodes) {
      try {
        final explanation = await graph.explainRecall(
          result.node.id,
          maxDepth: maxHops,
          log: false,
        );
        result.explanation = explanation;
      } catch (_) {
        // silently skip nodes that can't be explained
      }
    }
  }
}
