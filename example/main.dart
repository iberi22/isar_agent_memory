import 'dart:io';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

Future<void> main() async {
  print('====================================================');
  print('          AGENT MEMORY SDK DEMONSTRATION            ');
  print('====================================================\n');

  // Initialize Isar Core for pure Dart environment
  await Isar.initializeIsarCore(download: true);

  // 1. Setup deterministic Hash Embedding Backend
  // A local-first hash-based embedding adapter guarantees we can run this
  // demo offline/without API keys, while still producing reproducible vector search.
  final backend = HashEmbeddingBackend(dimension: 256);
  final adapter = BackendEmbeddingsAdapter(backend: backend);
  await adapter.ensureLoaded();

  // Create clean temporary directory for Isar database
  final dbDir = Directory('./exampledb');
  if (await dbDir.exists()) {
    try {
      await dbDir.delete(recursive: true);
    } catch (_) {
      // Ignored if directory cannot be deleted immediately
    }
  }
  await dbDir.create(recursive: true);

  // Open Isar Database with schemas from the package
  final isar = await Isar.open(
    [MemoryNodeSchema, MemoryEdgeSchema],
    directory: dbDir.path,
  );

  // Create our universal Memory Graph
  final graph = MemoryGraph(isar, embeddingsAdapter: adapter);

  try {
    // -------------------------------------------------------------------
    // Step 2: GRAPH CRUD OPERATIONS
    // -------------------------------------------------------------------
    print('--- [1/5] GRAPH CRUD OPERATIONS ---');

    // CREATE: Store nodes representing concepts or facts with auto-generated embeddings
    final node1Id = await graph.storeNodeWithEmbedding(
      content: 'Seattle is a beautiful city in Washington state known for rain.',
      type: 'location_fact',
    );
    final node2Id = await graph.storeNodeWithEmbedding(
      content: 'The Space Needle is an iconic observation tower located in Seattle.',
      type: 'landmark_fact',
    );
    print('Created Node 1 (Seattle) with ID: $node1Id');
    print('Created Node 2 (Space Needle) with ID: $node2Id');

    // CREATE EDGE: Connect the nodes via a directed relationship edge
    final edgeId = await graph.storeEdge(MemoryEdge(
      fromNodeId: node2Id,
      toNodeId: node1Id,
      relation: 'is_located_in',
      weight: 0.95,
    ));
    print('Created Edge connecting Node 2 -> Node 1 (ID: $edgeId)\n');

    // READ: Retrieve nodes from the graph
    final fetchedNode1 = await graph.getNode(node1Id);
    if (fetchedNode1 != null) {
      print('Retrieved Node 1 content: "${fetchedNode1.content}"');
    }

    // UPDATE: Modify the node content (e.g., add new details)
    if (fetchedNode1 != null) {
      fetchedNode1.content = 'Seattle is a beautiful city in Washington (WA) known for rain and tech companies.';
      await graph.storeNode(fetchedNode1);
      print('Updated Node 1 content.');
    }

    // SEMANTIC SEARCH: Search the graph using semantic similarity
    print('\nPerforming Semantic Search for "Space Needle tower"...');
    final queryVector = await adapter.embed('Space Needle tower');
    final searchResults = await graph.semanticSearch(queryVector, topK: 2);
    for (final result in searchResults) {
      print(' - Node ID: ${result.node.id}, Content: "${result.node.content}"');
      print('   Similarity Distance: ${result.distance.toStringAsFixed(4)} (Provider: ${result.provider})');
    }

    // EXPLAIN RECALL: Get graph path explanation
    if (searchResults.isNotEmpty) {
      print('\nExplaining recall path for the top match:');
      final explanation = await graph.explainRecall(
        searchResults.first.node.id,
        queryEmbedding: queryVector,
      );
      print(' Explanation:\n $explanation\n');
    }

    // -------------------------------------------------------------------
    // Step 3: SESSION ISOLATION & CONTEXT
    // -------------------------------------------------------------------
    print('--- [2/5] SESSION & TENANT ISOLATION ---');

    // Create isolated contexts for different users using SessionContext
    final aliceSession = SessionContext(graph: graph, sessionId: 'alice-session-456');
    final bobSession = SessionContext(graph: graph, sessionId: 'bob-session-789');

    // Store private information scoped to each user
    await aliceSession.store('Alice prefers drinking hot Earl Grey tea in the morning.', type: 'preference');
    await bobSession.store('Bob prefers drinking black iced coffee in the morning.', type: 'preference');

    print('Stored session-scoped preference for Alice.');
    print('Stored session-scoped preference for Bob.');

    // Search inside Alice\'s session
    print('\nSearching for "morning beverage preference" in Alice\'s session:');
    final aliceQueryVector = await adapter.embed('morning beverage preference');
    final aliceResults = await aliceSession.semanticSearch(aliceQueryVector, topK: 3);
    for (final r in aliceResults) {
      print(' - [Alice Session] Found: "${r.node.content}" (Distance: ${r.distance.toStringAsFixed(4)})');
    }

    // Search inside Bob\'s session
    print('\nSearching for "morning beverage preference" in Bob\'s session:');
    final bobQueryVector = await adapter.embed('morning beverage preference');
    final bobResults = await bobSession.semanticSearch(bobQueryVector, topK: 3);
    for (final r in bobResults) {
      print(' - [Bob Session] Found: "${r.node.content}" (Distance: ${r.distance.toStringAsFixed(4)})');
    }
    print('');

    // -------------------------------------------------------------------
    // Step 4: QUERY ROUTER (HEURISTIC RETRIEVAL)
    // -------------------------------------------------------------------
    print('--- [3/5] AGENTIC QUERY ROUTER ---');

    final router = QueryRouter(graph: graph, embeddings: adapter);

    // Formulate queries with different intents: temporal, graph/relationship, precise terms, vector
    final queries = [
      'What did Alice do yesterday?', // Temporal intent
      'How is the Space Needle related to Seattle?', // Graph/relationship intent
      'Specific protocol WA standard format v1', // Precise term / hybrid intent
      'Beautiful rainy cities', // Standard vector intent
    ];

    for (final query in queries) {
      // 1. Classify the query intent and confidence
      final plan = router.classify(query);
      print('Query: "$query"');
      print(' -> Strategy:  ${plan.strategy.name.toUpperCase()}');
      print(' -> Confidence: ${(plan.confidence * 100).toStringAsFixed(0)}%');
      print(' -> Reasoning:  ${plan.reasoning}');

      // 2. Execute the routed strategy
      final results = await router.execute(plan);
      print(' -> Results count: ${results.length}');
      if (results.isNotEmpty) {
        print(' -> Top Result: "${results.first.node.content}" (Source: ${results.first.source})');
      }
      print('----------------------------------------------------');
    }
    print('');

    // -------------------------------------------------------------------
    // Step 5: COMPOSABLE RAG PIPELINE
    // -------------------------------------------------------------------
    print('--- [4/5] COMPOSABLE RAG PIPELINE ---');

    // Set up a custom composable RAG pipeline
    final pipeline = MemoryPipeline();

    // Add a custom Query Expansion hook (e.g. expands acronym "WA" to "Washington State")
    pipeline.addExpansionHook(_CustomQueryExpansionHook());

    // Add retrieval stage: use the built-in vector search retrieval hook
    pipeline.addRetrievalHook(VectorRetrievalHook(
      graph: graph,
      embeddings: adapter,
      topK: 3,
    ));

    // Add enrichment stage: use HiRAG multi-hop explanation hook to append graph path context
    pipeline.addEnrichmentHook(MultiHopEnrichmentHook(
      graph: graph,
      maxHops: 2,
    ));

    // Run the pipeline for a query containing the WA abbreviation
    final pipelineQuery = 'What is there to do in WA?';
    print('Running custom pipeline for: "$pipelineQuery"');

    final pipelineResult = await pipeline.run(pipelineQuery);
    print('Pipeline elapsed time: ${pipelineResult.elapsed.inMilliseconds}ms');
    print('Expanded Queries: ${pipelineResult.context.expandedQueries}');
    print('Pipeline Results:');
    for (final result in pipelineResult.results) {
      print(' - Node ID: ${result.node.id}, Content: "${result.node.content}"');
      print('   Score: ${result.score.toStringAsFixed(4)}, Source: ${result.source}');
      print('   Enrichment Explanation: ${result.explanation}');
    }
    print('');

    // -------------------------------------------------------------------
    // Step 6: RESULT RE-RANKING STRATEGIES
    // -------------------------------------------------------------------
    print('--- [5/5] RESULT RE-RANKING ---');

    // Create a pool of nodes of varying relevance for re-ranking
    final searchOutput = <({MemoryNode node, double score})>[];

    final nodesToRank = [
      'Seattle rain is very constant during the winter months.',
      'Washington state has many hiking trails near Mount Rainier.',
      'Drinking Earl Grey tea is highly recommended in Seattle.',
      'Space Needle is tall.',
    ];

    for (var i = 0; i < nodesToRank.length; i++) {
      final node = MemoryNode(content: nodesToRank[i]);
      // Assign deterministic embeddings for diversity comparison
      node.embedding = MemoryEmbedding(vector: await adapter.embed(nodesToRank[i]));
      searchOutput.add((node: node, score: 0.9 - (i * 0.1)));
    }

    print('Original Search Result Order (highest score first):');
    for (final r in searchOutput) {
      print(' - [Score: ${r.score.toStringAsFixed(2)}] "${r.node.content}"');
    }

    // 1. BM25 Re-ranker (lexical keyword matching)
    print('\nApplying BM25 Re-ranking for query "rain Seattle":');
    final bm25Ranker = BM25ReRanker();
    final bm25Results = await bm25Ranker.reRank(searchOutput, query: 'rain Seattle');
    for (final r in bm25Results) {
      print(' - "${r.node.content}"');
    }

    // 2. Diversity Re-ranker (uses Cosine Similarity on embeddings to avoid redundant topics)
    print('\nApplying Diversity Re-ranking to maximize informational novelty:');
    final diversityRanker = DiversityReRanker();
    final diverseResults = await diversityRanker.reRank(searchOutput);
    for (final r in diverseResults) {
      print(' - "${r.node.content}"');
    }

    // Clean up nodes
    print('\nCleaning up and closing database...');
    // DELETE: Demonstrate deleting nodes
    final deletedCount = await graph.deleteNode(node1Id);
    print('Deleted Node 1 (Seattle). Affected nodes/edges count: $deletedCount');

  } finally {
    // Make sure we release native backend resources and close Isar cleanly
    await adapter.dispose();
    await isar.close();
    print('\nDatabase closed successfully. Demo complete!');
    print('====================================================');
  }
}

/// Custom Query Expansion Hook implementation.
/// Rewrites queries containing "WA" to "Washington State" to improve retrieval recall.
class _CustomQueryExpansionHook implements QueryExpansionHook {
  @override
  int get priority => 10; // lower priority runs first

  @override
  Future<void> expand(PipelineContext context) async {
    final query = context.query;
    if (query.contains('WA')) {
      final expanded = query.replaceAll('WA', 'Washington State');
      context.expandedQueries = [expanded];
    } else {
      context.expandedQueries = [query];
    }
  }
}
