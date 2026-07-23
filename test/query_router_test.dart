import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

// Simple mock for testing without API calls
class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'mock';

  @override
  int get dimension => 384;

  @override
  Future<List<double>> embed(String text) async {
    // Generates a simple, deterministic vector based on text content
    return List.generate(384, (i) => (text.length + i) / 1000.0);
  }
}

// Custom mock pipeline to test runPipeline custom routing
class MockMemoryPipeline extends MemoryPipeline {
  bool runCalled = false;

  @override
  Future<MemoryPipelineResult> run(
    String query, {
    String? sessionId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    runCalled = true;
    final context = PipelineContext(query: query, sessionId: sessionId)
      ..retrievedNodes = [
        RetrievedNode(
          node: MemoryNode(content: 'Custom Pipeline Result'),
          score: 1.0,
          source: 'custom_mock',
        )
      ];
    return MemoryPipelineResult(
      results: context.retrievedNodes,
      elapsed: Duration.zero,
      context: context,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoryGraph memoryGraph;
  late EmbeddingsAdapter embeddingsAdapter;
  late QueryRouter queryRouter;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'test_router_db',
    );

    embeddingsAdapter = MockEmbeddingsAdapter();
    memoryGraph = MemoryGraph(isar, embeddingsAdapter: embeddingsAdapter);
    queryRouter = QueryRouter(graph: memoryGraph, embeddings: embeddingsAdapter);

    await isar.writeTxn(() async {
      await isar.clear();
    });
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('QueryRouter.classify', () {
    test('Classify: vector (default) query', () {
      final plan = queryRouter.classify('how does neural retrieval work?');
      expect(plan.strategy, QueryStrategy.vector);
      expect(plan.confidence, 0.65);
      expect(plan.reasoning, contains('Default routing'));
    });

    test('Classify: hybrid precise term query', () {
      final plan1 = queryRouter.classify('find specific version standard of protocol');
      expect(plan1.strategy, QueryStrategy.hybrid);
      expect(plan1.confidence, 0.75);
      expect(plan1.reasoning, contains('Precise terms detected'));

      final plan2 = queryRouter.classify('regex pattern compilation');
      expect(plan2.strategy, QueryStrategy.hybrid);
    });

    test('Classify: temporal query', () {
      final plan1 = queryRouter.classify('what did the user do yesterday?');
      expect(plan1.strategy, QueryStrategy.temporal);
      expect(plan1.confidence, 0.85);

      final plan2 = queryRouter.classify('show results from last week');
      expect(plan2.strategy, QueryStrategy.temporal);
    });

    test('Classify: graph / relation query', () {
      final plan1 = queryRouter.classify('how is concept A related to concept B?');
      expect(plan1.strategy, QueryStrategy.graph);
      expect(plan1.confidence, 0.8);

      final plan2 = queryRouter.classify('traverse the path between the nodes');
      expect(plan2.strategy, QueryStrategy.graph);
    });

    test('Classify: hierarchical / summary query', () {
      final plan1 = queryRouter.classify('summarize the key achievements');
      expect(plan1.strategy, QueryStrategy.hierarchical);
      expect(plan1.confidence, 0.75);

      final plan2 = queryRouter.classify('give me an overview of the topic');
      expect(plan2.strategy, QueryStrategy.hierarchical);
    });

    test('Classify: multiStrategy / multi-part query', () {
      final plan1 = queryRouter.classify('what is a vector search? and also what is a hybrid search?');
      expect(plan1.strategy, QueryStrategy.multiStrategy);
      expect(plan1.confidence, 0.7);
      expect(plan1.subQueries, isNotEmpty);
      expect(plan1.subQueries!.length, greaterThanOrEqualTo(2));

      final plan2 = queryRouter.classify('who did X? Or who did Y?');
      expect(plan2.strategy, QueryStrategy.multiStrategy);
    });

    test('Classify: clarify (too short/vague) query', () {
      final plan = queryRouter.classify('abc');
      expect(plan.strategy, QueryStrategy.clarify);
      expect(plan.confidence, 0.3);
      expect(plan.reasoning, contains('too short'));
    });

    test('Classify: clarify edge cases (empty and whitespace)', () {
      final planEmpty = queryRouter.classify('');
      expect(planEmpty.strategy, QueryStrategy.clarify);

      final planSpaces = queryRouter.classify('    ');
      expect(planSpaces.strategy, QueryStrategy.clarify);
    });

    test('Classify: entity query exception (short but looks like entity)', () {
      // "US" is short (< 5 chars) but starts with uppercase letter, so should fall back to vector (default) or other strategy
      final planEntity = queryRouter.classify('US');
      expect(planEntity.strategy, QueryStrategy.vector);
    });
  });

  group('QueryRouter.execute', () {
    test('Execute: vector search retrieves correct nodes', () async {
      final nodeId = await memoryGraph.storeNodeWithEmbedding(content: 'Neural retrieval mechanisms in 2026.');
      final plan = RoutingPlan(
        strategy: QueryStrategy.vector,
        query: 'neural retrieval',
        confidence: 0.8,
        reasoning: 'forced',
      );

      final results = await queryRouter.execute(plan);
      expect(results, isNotEmpty);
      expect(results.first.node.id, nodeId);
      expect(results.first.source, 'vector');
    });

    test('Execute: hybrid search combines text and vector', () async {
      final nodeId = await memoryGraph.storeNodeWithEmbedding(content: 'Specialized protocol v2 standard.');
      final plan = RoutingPlan(
        strategy: QueryStrategy.hybrid,
        query: 'protocol v2',
        confidence: 0.8,
        reasoning: 'forced',
      );

      final results = await queryRouter.execute(plan);
      expect(results, isNotEmpty);
      expect(results.first.node.id, nodeId);
      expect(results.first.source, 'hybrid');
    });

    test('Execute: temporal search with recent filter', () async {
      final now = DateTime.now();
      final nodeYesterday = MemoryNode(
        content: 'Action taken yesterday.',
        createdAt: now.subtract(const Duration(hours: 12)),
        embedding: MemoryEmbedding(
          vector: await embeddingsAdapter.embed('Action taken yesterday.'),
          provider: 'mock',
          dimension: 384,
        ),
      );
      final nodeLastYear = MemoryNode(
        content: 'Action taken last year.',
        createdAt: now.subtract(const Duration(days: 365)),
        embedding: MemoryEmbedding(
          vector: await embeddingsAdapter.embed('Action taken last year.'),
          provider: 'mock',
          dimension: 384,
        ),
      );

      final yesId = await memoryGraph.storeNode(nodeYesterday);
      final lyId = await memoryGraph.storeNode(nodeLastYear);

      // Query with temporal keyword "yesterday"
      final plan = RoutingPlan(
        strategy: QueryStrategy.temporal,
        query: 'what action was taken yesterday?',
        confidence: 0.85,
        reasoning: 'forced',
      );

      final results = await queryRouter.execute(plan);
      expect(results, isNotEmpty);
      final retrievedIds = results.map((r) => r.node.id).toList();
      expect(retrievedIds, contains(yesId));
      expect(retrievedIds, isNot(contains(lyId)));
      expect(results.first.source, 'temporal');
    });

    test('Execute: graph search enriches with connections', () async {
      final idA = await memoryGraph.storeNodeWithEmbedding(content: 'Concept Alpha');
      final idB = await memoryGraph.storeNodeWithEmbedding(content: 'Concept Beta');

      await memoryGraph.storeEdge(MemoryEdge(
        fromNodeId: idA,
        toNodeId: idB,
        relation: 'connected_to',
      ));

      final plan = RoutingPlan(
        strategy: QueryStrategy.graph,
        query: 'Concept Alpha connections',
        confidence: 0.8,
        reasoning: 'forced',
      );

      final results = await queryRouter.execute(plan);
      expect(results, isNotEmpty);
      final matchedResult = results.firstWhere((r) => r.node.id == idA);
      expect(matchedResult.source, 'graph');
      expect(matchedResult.explanation, contains('connected_to'));
    });

    test('Execute: hierarchical search performs multi-hop retrieval', () async {
      final nodeAId = await memoryGraph.storeNodeWithEmbedding(content: 'Detail item A.');
      final nodeBId = await memoryGraph.storeNodeWithEmbedding(content: 'Detail item B.');

      final summaryId = await memoryGraph.createSummaryNode(
        summaryContent: 'Summary overview of items.',
        childNodeIds: [nodeAId, nodeBId],
        layer: 1,
      );

      final plan = RoutingPlan(
        strategy: QueryStrategy.hierarchical,
        query: 'Summary overview',
        confidence: 0.8,
        reasoning: 'forced',
      );

      final results = await queryRouter.execute(plan);
      expect(results, isNotEmpty);
      expect(results.first.source, 'hierarchical');
      expect(results.first.explanation, contains('parent nodes:'));
      expect(results.first.explanation, contains(summaryId.toString()));
    });

    test('Execute: clarify returns empty list immediately', () async {
      final plan = RoutingPlan(
        strategy: QueryStrategy.clarify,
        query: 'abc',
        confidence: 0.3,
        reasoning: 'too short',
      );
      final results = await queryRouter.execute(plan);
      expect(results, isEmpty);
    });
  });

  group('QueryRouter.runPipeline', () {
    test('runPipeline (default) classifies and executes query', () async {
      final nodeId = await memoryGraph.storeNodeWithEmbedding(content: 'Factual information content.');
      final result = await queryRouter.runPipeline('Factual information content.');

      expect(result.results, isNotEmpty);
      expect(result.results.first.node.id, nodeId);
      expect(result.context.query, 'Factual information content.');
      expect(result.context.metadata['strategy'], QueryStrategy.vector.name);
      expect(result.context.metadata['confidence'], 0.65);
    });

    test('runPipeline overrides with custom pipeline if provided', () async {
      final mockPipeline = MockMemoryPipeline();
      final result = await queryRouter.runPipeline(
        'Some sample query',
        pipeline: mockPipeline,
      );

      expect(mockPipeline.runCalled, isTrue);
      expect(result.results, isNotEmpty);
      expect(result.results.first.node.content, 'Custom Pipeline Result');
    });
  });

  group('RoutingPlan.rank() logic (Multi-strategy Fusion and Sorting)', () {
    test('Fusion score boosting and sorting order', () async {
      // To thoroughly test the multi-strategy ranking and fusion logic:
      // Store a node that will be retrieved by both vector and hybrid search.
      final id1 = await memoryGraph.storeNodeWithEmbedding(content: 'Extremely unique content about neural algorithms.');
      final id2 = await memoryGraph.storeNodeWithEmbedding(content: 'Other random content.');

      final plan = RoutingPlan(
        strategy: QueryStrategy.multiStrategy,
        query: 'neural algorithms',
        confidence: 0.7,
        reasoning: 'forced',
      );

      final results = await queryRouter.execute(plan);

      // We expect the nodes to be merged, and the node with matching keywords (id1)
      // to be returned from multiple strategies and thus get a boosted score.
      expect(results, isNotEmpty);
      expect(results.first.node.id, id1);
      expect(results.first.source, 'fused'); // Merged nodes get labeled as 'fused'

      // Verify that the list is sorted in descending score order
      for (int i = 0; i < results.length - 1; i++) {
        expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
      }
    });

    test('RoutingPlan constructor and fields check', () {
      final plan = RoutingPlan(
        strategy: QueryStrategy.multiStrategy,
        query: 'query parts',
        subQueries: ['query', 'parts'],
        confidence: 0.95,
        reasoning: 'custom reasoning',
      );

      expect(plan.strategy, QueryStrategy.multiStrategy);
      expect(plan.query, 'query parts');
      expect(plan.subQueries, equals(['query', 'parts']));
      expect(plan.confidence, 0.95);
      expect(plan.reasoning, 'custom reasoning');
    });
  });
}
