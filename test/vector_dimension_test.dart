import 'dart:io';
import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/vector_index_objectbox.dart';
import 'package:isar_agent_memory/objectbox.g.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  final int dimension;
  @override
  final String providerName = 'mock';

  MockEmbeddingsAdapter(this.dimension);

  @override
  Future<List<double>> embed(String text) async {
    return List.generate(dimension, (i) => i.toDouble());
  }
}

void main() {
  late Isar isar;
  final tempDir = Directory.systemTemp.createTempSync('isar_test');

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: tempDir.path,
    );
  });

  tearDownAll(() async {
    await isar.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Vector Dimension Compatibility', () {
    test('MemoryGraph initializes with 768-dim adapter (default)', () async {
      final adapter = MockEmbeddingsAdapter(768);
      final obxDir = path.join(tempDir.path, 'obx_768');

      final index = ObjectBoxVectorIndex.open(
        directory: obxDir,
        dimension: 768,
      );

      final graph = MemoryGraph(isar, embeddingsAdapter: adapter, index: index);
      await graph.initialize();

      expect(index.dimension, equals(768));

      final nodeId = await graph.storeNodeWithEmbedding(content: 'test 768');
      expect(nodeId, isNotNull);

      final results =
          await graph.semanticSearch(await adapter.embed('test 768'));
      expect(results, isNotEmpty);
      expect(results.first.node.content, equals('test 768'));
    });

    test('MemoryGraph initializes with 384-dim adapter', () async {
      final adapter = MockEmbeddingsAdapter(384);
      final obxDir = path.join(tempDir.path, 'obx_384');

      // MemoryGraph should automatically pick 384 if we don't provide index
      // But for testing multiple in one run we might need different directories
      final index = ObjectBoxVectorIndex.open(
        directory: obxDir,
        dimension: 384,
      );

      final graph = MemoryGraph(isar, embeddingsAdapter: adapter, index: index);
      await graph.initialize();

      expect(index.dimension, equals(384));

      final nodeId = await graph.storeNodeWithEmbedding(content: 'test 384');
      expect(nodeId, isNotNull);

      final results =
          await graph.semanticSearch(await adapter.embed('test 384'));
      expect(results, isNotEmpty);
      expect(results.first.node.content, equals('test 384'));
    });

    test('ObjectBoxVectorIndex throws on unsupported dimension', () {
      final store = openStore(directory: path.join(tempDir.path, 'obx_fail'));
      expect(
        () => ObjectBoxVectorIndex(store: store, dimension: 512),
        throwsArgumentError,
      );
      store.close();
    });
  });
}
