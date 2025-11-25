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
    // Return a simple vector based on text length
    return List.generate(384, (i) => (text.length + i) / 1000.0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoryGraph memoryGraph;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'test_db',
    );
    memoryGraph = MemoryGraph(isar, embeddingsAdapter: MockEmbeddingsAdapter());
    await isar.writeTxn(() async => await isar.clear());
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('Semantic search with RecencyReRanker test', () async {
    final now = DateTime.now();
    await memoryGraph.storeNode(MemoryNode(
        content: 'older', createdAt: now.subtract(const Duration(days: 1))));
    await memoryGraph.storeNode(MemoryNode(content: 'newer', createdAt: now));

    final results = await memoryGraph.semanticSearchWithReRanking(
      await memoryGraph.embeddingsAdapter.embed('some query'),
      reranker: RecencyReRanker(),
      topK: 1,
    );

    expect(results.first.node.content, 'newer');
  });

  test('Hybrid search with BM25ReRanker test', () async {
    await memoryGraph.storeNode(MemoryNode(content: 'the quick brown fox'));
    await memoryGraph.storeNode(MemoryNode(content: 'a lazy dog'));
    await memoryGraph.storeNode(
        MemoryNode(content: 'the quick brown fox jumps over the lazy dog'));

    final results = await memoryGraph.hybridSearchWithReRanking(
      'quick fox',
      reranker: BM25ReRanker(),
      topK: 2,
    );

    expect(results[0].node.content, 'the quick brown fox');
    expect(
        results[1].node.content, 'the quick brown fox jumps over the lazy dog');
  });
}
