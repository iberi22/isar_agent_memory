import '../memory_graph.dart';
import '../llm_adapter.dart';
import '../models/memory_node.dart';
import '../reranking_strategy.dart';
import 'memory_pipeline.dart';
import 'medical_prompt_builder.dart';

/// Medical RAG Pipeline implementation.
class MedicalRagPipeline implements MemoryPipeline<String, RagContext> {
  final MemoryGraph memoryGraph;
  final LLMAdapter llm;
  final ReRankingStrategy? reranker;
  final MedicalPromptBuilder promptBuilder;

  MedicalRagPipeline({
    required this.memoryGraph,
    required this.llm,
    this.reranker,
    MedicalPromptBuilder? promptBuilder,
  }) : promptBuilder = promptBuilder ?? MedicalPromptBuilder();

  @override
  Future<RagContext> execute(String query) async {
    var context = RagContext(originalQuery: query);

    // 1. Normalization
    context = await QueryNormalizationStage().process(context);

    // 2. Decomposition (optional, for complex queries)
    context = await MedicalQueryDecompositionStage(llm, promptBuilder)
        .process(context);

    // 3. Hybrid Retrieval
    context = await HybridRetrievalStage(memoryGraph).process(context);

    // 4. Re-ranking
    if (reranker != null) {
      context = await ReRankingStage(reranker!).process(context);
    }

    // 5. Generation
    final prompt = promptBuilder.buildRagPrompt(
      query: context.currentQuery,
      contextNodes: context.retrievedNodes.map((r) => r.node).toList(),
    );
    final response = await llm.generate(prompt);
    context.generatedResponse = response;

    // 6. Evidence Citation
    context = await EvidenceCitationStage().process(context);

    // Add disclaimer
    context.generatedResponse =
        promptBuilder.wrapWithDisclaimer(context.generatedResponse!);

    return context;
  }
}

/// Stage to expand medical abbreviations.
class QueryNormalizationStage extends PipelineStage<RagContext, RagContext> {
  static const Map<String, String> abbreviations = {
    'TA': 'tensión arterial',
    'HTA': 'hipertensión arterial',
    'DM': 'diabetes mellitus',
    'IMC': 'índice de masa corporal',
    'EPOC': 'enfermedad pulmonar obstructiva crónica',
    'SNC': 'sistema nervioso central',
    'PCR': 'proteína C reactiva',
    'ECG': 'electrocardiograma',
  };

  @override
  Future<RagContext> process(RagContext context) async {
    String normalized = context.currentQuery;
    abbreviations.forEach((abbrev, expansion) {
      // Simple regex-like replacement for whole words
      final regex = RegExp('\\b$abbrev\\b', caseSensitive: false);
      normalized = normalized.replaceAll(regex, expansion);
    });
    context.currentQuery = normalized;
    return context;
  }
}

/// Stage to split complex queries using an LLM.
class MedicalQueryDecompositionStage
    extends PipelineStage<RagContext, RagContext> {
  final LLMAdapter llm;
  final MedicalPromptBuilder promptBuilder;

  MedicalQueryDecompositionStage(this.llm, this.promptBuilder);

  @override
  Future<RagContext> process(RagContext context) async {
    // Only decompose if the query is long enough or contains conjunctions
    if (context.currentQuery.length > 60 ||
        context.currentQuery.contains(' y ') ||
        context.currentQuery.contains(' e ')) {
      final prompt =
          promptBuilder.buildDecompositionPrompt(context.currentQuery);
      final response = await llm.generate(prompt);

      context.decomposedQueries = response
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length > 5)
          .toList();
    }

    if (context.decomposedQueries.isEmpty) {
      context.decomposedQueries = [context.currentQuery];
    }

    return context;
  }
}

/// Stage to retrieve nodes using hybrid search.
class HybridRetrievalStage extends PipelineStage<RagContext, RagContext> {
  final MemoryGraph memoryGraph;

  HybridRetrievalStage(this.memoryGraph);

  @override
  Future<RagContext> process(RagContext context) async {
    final allResults = <int, ({MemoryNode node, double score})>{};

    for (final q in context.decomposedQueries) {
      final results = await memoryGraph.hybridSearch(q, topK: 5, alpha: 0.5);
      for (final res in results) {
        final existing = allResults[res.node.id];
        if (existing == null || res.score > existing.score) {
          allResults[res.node.id] = res;
        }
      }
    }

    final sortedResults = allResults.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    context.retrievedNodes = sortedResults.take(10).toList();
    return context;
  }
}

/// Stage to re-rank retrieved nodes.
class ReRankingStage extends PipelineStage<RagContext, RagContext> {
  final ReRankingStrategy reranker;

  ReRankingStage(this.reranker);

  @override
  Future<RagContext> process(RagContext context) async {
    if (context.retrievedNodes.isEmpty) return context;

    context.retrievedNodes = reranker.reRank(
      context.retrievedNodes,
      query: context.currentQuery,
    );

    return context;
  }
}

/// Stage to attach source nodes to the generated response.
class EvidenceCitationStage extends PipelineStage<RagContext, RagContext> {
  @override
  Future<RagContext> process(RagContext context) async {
    if (context.generatedResponse == null) return context;

    final cited = <MemoryNode>[];
    for (var i = 0; i < context.retrievedNodes.length; i++) {
      final node = context.retrievedNodes[i].node;
      final citation = '[${i + 1}]';
      if (context.generatedResponse!.contains(citation)) {
        cited.add(node);
      }
    }

    context.citedNodes = cited;
    return context;
  }
}
