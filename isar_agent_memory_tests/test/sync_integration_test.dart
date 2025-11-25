import 'package:flutter_test/flutter_test.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/sync/sync_manager.dart';
import 'package:isar/isar.dart';
import 'dart:io';
import 'support/in_memory_index.dart'; // Import InMemoryVectorIndex

void main() {
  late MemoryGraph memoryGraph;
  late SyncManager syncManager;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    final isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: dir.path,
    );

    // Mock adapter
    final adapter = FallbackEmbeddingsAdapter(
      primary: _MockEmbeddingsAdapter(),
      fallback: _MockEmbeddingsAdapter(),
    );

    memoryGraph = MemoryGraph(isar,
        embeddingsAdapter: adapter, index: InMemoryVectorIndex());
    syncManager = SyncManager(memoryGraph);
    await syncManager.initialize(); // Random key
  });

  tearDown(() async {
    await memoryGraph.isar.close(deleteFromDisk: true);
  });

  test('SyncManager export and import loop', () async {
    // 1. Create some data
    final nodeId =
        await memoryGraph.storeNodeWithEmbedding(content: 'Secret Memory');
    final edgeId = await memoryGraph.storeEdge(
        MemoryEdge(fromNodeId: nodeId, toNodeId: nodeId, relation: 'self'));

    // 2. Export
    final encrypted = await syncManager.exportEncryptedSnapshot();
    expect(encrypted, isNotEmpty);

    // 3. Clear DB
    await memoryGraph.isar.writeTxn(() async {
      await memoryGraph.isar.clear();
    });
    expect(await memoryGraph.getNode(nodeId), isNull);

    // 4. Import
    await syncManager.importEncryptedSnapshot(encrypted);

    // 5. Verify
    final node = await memoryGraph.getNode(nodeId);
    expect(node, isNotNull);
    expect(node!.content, 'Secret Memory');

    final edges = await memoryGraph.getEdgesForNode(nodeId);
    expect(edges, isNotEmpty);
    expect(edges.first.relation, 'self');
  });
}

class _MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  int get dimension => 768;

  @override
  Future<List<double>> embed(String text) async {
    return List.filled(768, 0.1);
  }

  @override
  Future<List<List<double>>> embedDocuments(List<String> documents) async {
    return documents.map((_) => List.filled(768, 0.1)).toList();
  }

  @override
  Future<List<double>> embedQuery(String query) async {
    return List.filled(768, 0.1);
  }

  @override
  String get providerName => 'mock';
}
