import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/session_context.dart';
import 'package:isar_agent_memory/objectbox.g.dart';
import 'package:path/path.dart' as path;

class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'mock';

  @override
  int get dimension => 384;

  @override
  Future<List<double>> embed(String text) async {
    // Generate a simple deterministic vector of 384 dimensions
    final bytes = text.codeUnits;
    return List.generate(384, (i) {
      if (i < bytes.length) {
        return bytes[i] / 255.0;
      }
      return (i * 3) / 1000.0;
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late Store store;
  late MemoryGraph memoryGraph;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    tempDir = Directory.systemTemp.createTempSync('session_context_test');

    isar = await Isar.open(
      [MemoryNodeSchema, MemoryEdgeSchema],
      directory: tempDir.path,
      name: 'session_test_db',
    );

    final obxDir = path.join(tempDir.path, 'obx_store');
    store = openStore(directory: obxDir);
    final index = ObjectBoxVectorIndex(
      store: store,
      dimension: 384,
    );

    memoryGraph = MemoryGraph(
      isar,
      embeddingsAdapter: MockEmbeddingsAdapter(),
      index: index,
    );
    await memoryGraph.initialize();
  });

  tearDown(() async {
    store.close();
    await isar.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SessionContext Tests', () {
    test('Session isolation: store in A, not visible in B', () async {
      final sessionA = SessionContext(
        graph: memoryGraph,
        sessionId: 'session-a',
      );
      final sessionB = SessionContext(
        graph: memoryGraph,
        sessionId: 'session-b',
      );

      // Storing in session A
      final nodeAId = await sessionA.store('Private memory for session A');
      expect(nodeAId, isNotNull);

      // Storing in session B
      final nodeBId = await sessionB.store('Secret info for session B');
      expect(nodeBId, isNotNull);

      // Verify that Session A can only access its own memory
      final nodesA = await sessionA.getAll();
      expect(nodesA.length, equals(1));
      expect(nodesA.first.content, equals('Private memory for session A'));
      expect(await sessionA.count(), equals(1));

      // Verify that Session B can only access its own memory
      final nodesB = await sessionB.getAll();
      expect(nodesB.length, equals(1));
      expect(nodesB.first.content, equals('Secret info for session B'));
      expect(await sessionB.count(), equals(1));

      // Verify global graph still contains both (since they share the same database)
      final allNodes = await memoryGraph.isar.memoryNodes.where().findAll();
      expect(allNodes.length, equals(2));
    });

    test('Search scoped and filtered by session', () async {
      final sessionA = SessionContext(
        graph: memoryGraph,
        sessionId: 'session-a',
      );
      final sessionB = SessionContext(
        graph: memoryGraph,
        sessionId: 'session-b',
      );

      // Store similar content in both sessions
      await sessionA.store('The weather in London is cloudy.');
      await sessionB.store('The weather in London is sunny.');

      // Search inside Session A
      final queryEmbedding = await memoryGraph.embeddingsAdapter.embed('London weather');

      // 1. Semantic Search
      final semanticResultsA = await sessionA.semanticSearch(queryEmbedding, topK: 5);
      expect(semanticResultsA.length, equals(1));
      expect(semanticResultsA.first.node.content, contains('cloudy'));

      final semanticResultsB = await sessionB.semanticSearch(queryEmbedding, topK: 5);
      expect(semanticResultsB.length, equals(1));
      expect(semanticResultsB.first.node.content, contains('sunny'));

      // 2. Hybrid Search
      final hybridResultsA = await sessionA.hybridSearch('London', topK: 5);
      expect(hybridResultsA.length, equals(1));
      expect(hybridResultsA.first.node.content, contains('cloudy'));

      final hybridResultsB = await sessionB.hybridSearch('London', topK: 5);
      expect(hybridResultsB.length, equals(1));
      expect(hybridResultsB.first.node.content, contains('sunny'));
    });

    test('clear() removes only session nodes', () async {
      final sessionA = SessionContext(
        graph: memoryGraph,
        sessionId: 'session-a',
      );
      final sessionB = SessionContext(
        graph: memoryGraph,
        sessionId: 'session-b',
      );

      await sessionA.store('Memory 1');
      await sessionA.store('Memory 2');
      await sessionB.store('Memory 3');

      expect(await sessionA.count(), equals(2));
      expect(await sessionB.count(), equals(1));

      // Clear Session A
      final deletedCount = await sessionA.clear();
      expect(deletedCount, equals(2));

      // Session A should be empty
      expect(await sessionA.count(), equals(0));
      expect(await sessionA.getAll(), isEmpty);

      // Session B should remain completely intact
      expect(await sessionB.count(), equals(1));
      final nodesB = await sessionB.getAll();
      expect(nodesB.first.content, equals('Memory 3'));
    });

    test('Multiple sessions with combinations of sessionId and userId are independent and coexist correctly', () async {
      // Create session contexts with various combinations of sessionId and userId
      final contextS1U1 = SessionContext(graph: memoryGraph, sessionId: 's1', userId: 'u1');
      final contextS2U1 = SessionContext(graph: memoryGraph, sessionId: 's2', userId: 'u1');
      final contextS1U2 = SessionContext(graph: memoryGraph, sessionId: 's1', userId: 'u2');
      final contextGlobal = SessionContext(graph: memoryGraph); // no sessionId, no userId -> accesses all nodes as matchesScope returns true for everything if both are null

      await contextS1U1.store('Node S1-U1');
      await contextS2U1.store('Node S2-U1');
      await contextS1U2.store('Node S1-U2');

      // Verify contextS1U1 (only matches s1 and u1)
      final nodesS1U1 = await contextS1U1.getAll();
      expect(nodesS1U1.length, equals(1));
      expect(nodesS1U1.first.content, equals('Node S1-U1'));

      // Verify contextS2U1 (only matches s2 and u1)
      final nodesS2U1 = await contextS2U1.getAll();
      expect(nodesS2U1.length, equals(1));
      expect(nodesS2U1.first.content, equals('Node S2-U1'));

      // Verify contextS1U2 (only matches s1 and u2)
      final nodesS1U2 = await contextS1U2.getAll();
      expect(nodesS1U2.length, equals(1));
      expect(nodesS1U2.first.content, equals('Node S1-U2'));

      // Verify contextGlobal accesses all nodes (since both are null)
      final nodesGlobal = await contextGlobal.getAll();
      expect(nodesGlobal.length, equals(3));
    });
  });
}
