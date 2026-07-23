# Modular RAG Pipeline Tutorial

This tutorial provides an in-depth guide on using and extending the **Modular Retrieval-Augmented Generation (RAG) Pipeline** in the `isar_agent_memory` package (introduced in v0.6.0).

By leveraging a composable, hook-driven architecture, you can insert domain-specific retrieval, expansion, re-ranking, enrichment, and evaluation logic into your AI agent's memory retrieval workflow without editing the core package.

---

## 1. Composable Pipeline Architecture

The modular RAG pipeline represents a state-of-the-art approach to knowledge recall. Instead of a monolithic vector search, the pipeline processes requests in 5 distinct, sequential stages:

```
Query ──► [Query Expansion] ──► [Retrieval] ──► [Re-ranking] ──► [Enrichment] ──► [Evaluation] ──► Result
```

Within each stage, multiple hooks can be registered. They are executed sequentially in order of priority (lower priority values run first).

---

## 2. Pipeline Stages & Custom Hooks

Each stage is defined by an abstract Dart interface. To implement custom behavior for your application (e.g., healthcare-specific terminology expansion or multi-modal enrichment), simply write a class implementing the respective interface.

### Stage 1: Query Expansion (`QueryExpansionHook`)
Rewrites, decomposes, or expands the raw user query.

**Use Cases**:
- Expand domain-specific abbreviations or synonyms (e.g., "BP" to "blood pressure").
- Translate queries to align with knowledge bases.
- Decompose complex compound prompts into simpler sub-queries.

```dart
import 'package:isar_agent_memory/isar_agent_memory.dart';

class MedicalAbbreviationExpander implements QueryExpansionHook {
  @override
  int get priority => 10;

  @override
  Future<void> expand(PipelineContext context) async {
    String query = context.query;

    // Replace abbreviation examples
    if (query.toUpperCase().contains('TA')) {
      query = query.replaceAll(RegExp(r'\bTA\b', caseSensitive: false), 'tensión arterial (blood pressure)');
    }
    if (query.toUpperCase().contains('FC')) {
      query = query.replaceAll(RegExp(r'\bFC\b', caseSensitive: false), 'frecuencia cardíaca (heart rate)');
    }

    context.expandedQueries.add(query);
  }
}
```

---

### Stage 2: Retrieval (`RetrievalHook`)
Fetches candidate nodes from one or more underlying indices or external knowledge providers. Results are appended to `PipelineContext.retrievedNodes`.

**Built-In Retrievers**:
- `VectorRetrievalHook`: Queries vector databases using cosine/Euclidean distance.
- `HybridRetrievalHook`: Merges vector search results and Isar full-text matches.

**Custom Retriever Example**:
```dart
class StaticEntityRetriever implements RetrievalHook {
  final MemoryGraph graph;

  StaticEntityRetriever(this.graph);

  @override
  int get priority => 20;

  @override
  Future<void> retrieve(PipelineContext context) async {
    // Attempt to pull a specific configured memory or hardcoded fallback
    if (context.query.contains('system profile')) {
      final node = MemoryNode(
        content: 'System Profile: OrionHealth Core Agent Framework v3.0.',
        type: 'system',
      );

      context.retrievedNodes.add(RetrievedNode(
        node: node,
        score: 1.0,
        source: 'static_index',
        explanation: 'Direct keyword match for system configuration.',
      ));
    }
  }
}
```

---

### Stage 3: Re-ranking (`ReRankingHook`)
Scores, filters, and re-orders the accumulated retrieved nodes.

**Use Cases**:
- Run a heavy cross-encoder neural model via remote API to re-sort items.
- Filter out duplicate nodes or apply Maximal Marginal Relevance (MMR) for result diversity.
- Boost nodes with higher recency.

```dart
class DiversityFilterReranker implements ReRankingHook {
  @override
  int get priority => 10;

  @override
  Future<void> reRank(PipelineContext context) async {
    // Keep only nodes with score >= 0.4
    context.retrievedNodes = context.retrievedNodes
        .where((r) => r.score >= 0.4)
        .toList();

    // Sort descending by score
    context.retrievedNodes.sort((a, b) => b.score.compareTo(a.score));
  }
}
```

---

### Stage 4: Enrichment (`EnrichmentHook`)
Hydrates retrieved nodes with additional context, parent metadata, or explanatory reasoning.

**Built-In Enrichment**:
- `MultiHopEnrichmentHook`: Navigates hierarchical graphs upward to aggregate abstract summary parents.

**Custom Enrichment Example**:
```dart
class CitationEnrichmentHook implements EnrichmentHook {
  @override
  int get priority => 50;

  @override
  Future<void> enrich(PipelineContext context) async {
    for (final result in context.retrievedNodes) {
      final docSource = result.node.metadata?['source'] ?? 'Unknown Source';
      result.explanation = '${result.explanation ?? ""}\n[Citation]: $docSource';
    }
  }
}
```

---

### Stage 5: Evaluation (`EvaluationHook`)
Performs an quality check over the consolidated results. Returns an `EvalDecision` (`accept`, `retry`, or `clarify`).

```dart
class ConfidenceEvaluator implements EvaluationHook {
  @override
  int get priority => 100;

  @override
  Future<EvalDecision> evaluate(PipelineContext context) async {
    if (context.retrievedNodes.isEmpty) {
      // Ask user to provide more context
      return EvalDecision.clarify;
    }

    final topScore = context.retrievedNodes.first.score;
    if (topScore < 0.3) {
      // Insufficient quality - rewrite/retry query expansion
      return EvalDecision.retry;
    }

    return EvalDecision.accept;
  }
}
```

---

## 3. Assembling the Pipeline

Below is a complete, ready-to-run pipeline assembly showing how custom and built-in hooks are configured, orchestrated, and executed.

```dart
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

void main() async {
  // 1. Setup mock/real instances
  late Isar isar; // instantiated isar DB
  late EmbeddingsAdapter embeddingsAdapter; // instantiated embeddings adapter

  final graph = MemoryGraph(isar, embeddingsAdapter: embeddingsAdapter);

  // 2. Instantiate our pipeline
  final pipeline = MemoryPipeline()
    ..maxIterations = 2; // Prevention from infinite loops during 'retry' decisions

  // 3. Register composable hooks
  pipeline.addExpansionHook(MedicalAbbreviationExpander());

  pipeline.addRetrievalHook(VectorRetrievalHook(
    graph: graph,
    embeddings: embeddingsAdapter,
    topK: 3,
  ));

  pipeline.addRetrievalHook(StaticEntityRetriever(graph));

  pipeline.addReRankingHook(DiversityFilterReranker());

  pipeline.addEnrichmentHook(MultiHopEnrichmentHook(
    graph: graph,
    maxHops: 2,
  ));

  pipeline.addEvaluationHook(ConfidenceEvaluator());

  // 4. Run the pipeline
  final result = await pipeline.run(
    "What is the patient's current TA?",
    sessionId: "session_user_123",
    userId: "patient_orion_456",
  );

  // 5. Inspect results
  print('Retrieval elapsed: ${result.elapsed.inMilliseconds}ms');
  for (final candidate in result.results) {
    print('-----------------------------------------');
    print('Content: ${candidate.node.content}');
    print('Source: ${candidate.source}');
    print('Score: ${candidate.score}');
    print('Explanation: ${candidate.explanation}');
  }
}
```

---

## 4. Multi-Tenant Workspace Isolation

When running in shared multi-tenant or multi-user contexts, you must isolate memory partitions. This is accomplished using `SessionContext`.

You can filter queries and nodes dynamically by injecting active session variables inside the pipeline metadata:

```dart
final session = SessionContext(
  tenantId: "hospital_north_clinic",
  userId: "doctor_smith",
  sessionId: "active_session_99",
);

// Run the pipeline within the established session boundary
final result = await pipeline.run(
  "Check blood results.",
  sessionId: session.sessionId,
  userId: session.userId,
  metadata: {
    'tenantId': session.tenantId,
  },
);
```

---

## 5. Intelligent Query Router

Before executing the RAG pipeline, you can use the lightweight `QueryRouter` to categorize and route the incoming question to the optimal query strategy. This avoids running heavy, expensive multi-hop graphs for basic keyword questions.

```dart
final router = QueryRouter();

final plan = router.route("Find medical notes from 3 days ago");

print('Primary Strategy selected: ${plan.strategy}');
// Strategy will resolve to QueryStrategy.temporal based on keywords.

if (plan.strategy == QueryStrategy.temporal) {
  // Use a specialized temporal retrieval hook or recency-boosted pipeline
} else {
  // Fallback to default pipeline execution
}
```

By dynamically combining the `QueryRouter`, `SessionContext`, and the 5-stage composable `MemoryPipeline`, you can build scalable, high-performance RAG workflows tailored to any business or cognitive application.
