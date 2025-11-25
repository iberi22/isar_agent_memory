import 'package:flutter_test/flutter_test.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar/isar.dart';

// Simple mock for testing without API calls
class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'mock';

  @override
  int get dimension => 384;

  @override
  Future<List<double>> embed(String text) async {
    return List.generate(384, (i) => (text.length + i) / 1000.0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoryGraph memoryGraph;
  late EmbeddingsAdapter embeddingsAdapter;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'test_db',
    );

    embeddingsAdapter = MockEmbeddingsAdapter();
    memoryGraph = MemoryGraph(isar, embeddingsAdapter: embeddingsAdapter);

    await isar.writeTxn(() async {
      await isar.clear();
    });
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('multiHopSearch returns enriched results with context', () async {
    // 1. Setup: Create a small hierarchy
    // Layer 0
    final nodeAId = await memoryGraph.storeNodeWithEmbedding(
        content: 'Details about topic A.');
    final nodeBId = await memoryGraph.storeNodeWithEmbedding(
        content: 'Details about topic B.');

    // Layer 1 (Summary of A and B)
    final summary1Id = await memoryGraph.createSummaryNode(
      summaryContent: 'Summary of topics A and B.',
      childNodeIds: [nodeAId, nodeBId],
      layer: 1,
    );

    // 2. Execute: Search for something in layer 0
    final queryEmbedding = await embeddingsAdapter.embed('topic A');
    final results = await memoryGraph.multiHopSearch(
      queryEmbedding: queryEmbedding,
      topK: 1,
    );

    // 3. Verify: Check the results
    expect(results, isNotEmpty);
    expect(results.first.node.id, nodeAId);
    expect(results.first.context, isNotEmpty);
    expect(results.first.context.first.id, summary1Id);
  });
}
