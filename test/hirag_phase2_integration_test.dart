import 'package:flutter_test/flutter_test.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar/isar.dart';

// Mock LLMAdapter for testing without actual API calls
class MockLLMAdapter implements LLMAdapter {
  @override
  Future<String> generate(String prompt) async {
    return 'This is a mock summary.';
  }
}

// Simple mock embeddings adapter
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

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'test_db',
    );

    // Use a mock embeddings adapter to avoid actual API calls for embeddings
    final embeddingsAdapter = MockEmbeddingsAdapter();
    memoryGraph = MemoryGraph(isar, embeddingsAdapter: embeddingsAdapter);

    // Clean up database before each test
    await isar.writeTxn(() async {
      await isar.clear();
    });
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('autoSummarizeLayer creates a summary node and correct relationships',
      () async {
    // 1. Setup: Create some nodes in layer 0
    final node1Id =
        await memoryGraph.storeNodeWithEmbedding(content: 'The sky is blue.');
    final node2Id = await memoryGraph.storeNodeWithEmbedding(
        content: 'The grass is green.');

    // 2. Execute: Run auto-summarization
    final llmAdapter = MockLLMAdapter();
    final summaryNodeId = await memoryGraph.autoSummarizeLayer(
      layerIndex: 0,
      llmAdapter: llmAdapter,
    );

    // 3. Verify: Check the results
    final summaryNode = await memoryGraph.getNode(summaryNodeId);
    expect(summaryNode, isNotNull);
    expect(summaryNode!.layer, 1);
    expect(summaryNode.content, 'This is a mock summary.');

    // Verify 'summary_of' relationships (Child -> Summary)
    final edgesFromNode1 = await memoryGraph.getEdgesForNode(node1Id);
    expect(
        edgesFromNode1.any((e) =>
            e.toNodeId == summaryNodeId &&
            e.relation == HierarchicalMemoryGraph.relationSummaryOf),
        isTrue);

    final edgesFromNode2 = await memoryGraph.getEdgesForNode(node2Id);
    expect(
        edgesFromNode2.any((e) =>
            e.toNodeId == summaryNodeId &&
            e.relation == HierarchicalMemoryGraph.relationSummaryOf),
        isTrue);

    // Verify 'part_of' relationships (Summary -> Child)
    final edgesFromSummary = await memoryGraph.getEdgesForNode(summaryNodeId);
    expect(
        edgesFromSummary.any((e) =>
            e.toNodeId == node1Id &&
            e.relation == HierarchicalMemoryGraph.relationPartOf),
        isTrue);
    expect(
        edgesFromSummary.any((e) =>
            e.toNodeId == node2Id &&
            e.relation == HierarchicalMemoryGraph.relationPartOf),
        isTrue);
  });
}
