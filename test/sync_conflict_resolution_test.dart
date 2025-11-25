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
    return List.generate(384, (i) => (text.length + i) / 1000.0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoryGraph memoryGraph;
  late SyncManager syncManager;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: '.',
      name: 'test_db',
    );
    memoryGraph = MemoryGraph(isar, embeddingsAdapter: MockEmbeddingsAdapter());
    syncManager = SyncManager(memoryGraph);
    await syncManager.initialize(encryptionKey: List<int>.filled(32, 1));
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('LWW conflict resolution test', () async {
    // 1. Create a node and export it
    final originalNode = MemoryNode(
      content: 'Original content',
      modifiedAt: DateTime.now().subtract(Duration(minutes: 5)),
    );
    await memoryGraph.storeNode(originalNode);
    final snapshot1 = await syncManager.exportEncryptedSnapshot();

    // 2. Modify the node with a newer timestamp and export
    final updatedNode = MemoryNode(
      uuid: originalNode.uuid,
      content: 'Newer content',
      modifiedAt: DateTime.now(),
    );
    await memoryGraph.storeNode(updatedNode);
    final snapshot2 = await syncManager.exportEncryptedSnapshot();

    // 3. Import the older snapshot first, then the newer one
    await syncManager.importEncryptedSnapshot(snapshot1);
    await syncManager.importEncryptedSnapshot(snapshot2);

    // 4. Verify that the newer content wins
    final nodes = await memoryGraph.isar.memoryNodes.where().findAll();
    expect(nodes.length, 1);
    expect(nodes.first.content, 'Newer content');
  });
}
