import 'dart:io';
import 'package:test/test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/embeddings_adapter.dart';

// Mock implementation for testing without real API calls
class MockEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'mock';

  @override
  int get dimension => 4;

  @override
  Future<List<double>> embed(String text) async {
    // Return a fixed-size vector for predictability in tests
    return List.generate(dimension, (i) => text.length.toDouble() + i);
  }
}

void main() {
  group('MemoryGraph Tests', () {
    late Isar isar;
    late MemoryGraph graph;
    const testDbPath = './testdb';

    setUpAll(() async {
      // Initialize Isar for pure Dart environment
      stderr.writeln('Attempting to initialize IsarCore...');
      try {
        await Isar.initializeIsarCore(download: true);
        stderr.writeln('IsarCore initialized successfully.');
      } catch (e) {
        stderr.writeln('Error initializing IsarCore: $e');
        rethrow;
      }
    });

    setUp(() async {
      // Create a clean directory for each test
      stderr.writeln('Creating test directory: $testDbPath');
      await Directory(testDbPath).create(recursive: true);
      stderr.writeln('Test directory created.');
      stderr.writeln('Attempting to open Isar database...');
      try {
        isar = await Isar.open(
          [MemoryNodeSchema, MemoryEdgeSchema],
          inspector: false,
          directory: testDbPath,
        );
        stderr.writeln('Isar database opened successfully.');
      } catch (e) {
        stderr.writeln('Error opening Isar database: $e');
        rethrow;
      }
      // Use the mock adapter for tests
      graph = MemoryGraph(isar, embeddingsAdapter: MockEmbeddingsAdapter());
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      // Clear the dvdb collection to ensure no state leakage between tests
      graph.clearVectorCollection();
    });

    test('store and retrieve node', () async {
      final node = MemoryNode(content: 'Hello, world!');
      final id = await graph.storeNode(node);
      final fetched = await graph.getNode(id);
      expect(fetched, isNotNull);
      expect(fetched!.content, equals('Hello, world!'));
    });

    test('degree is initialized by default', () async {
      final node = MemoryNode(content: 'Test degree initialization');
      final id = await graph.storeNode(node);
      final fetched = await graph.getNode(id);

      expect(fetched, isNotNull);
      expect(fetched!.degree, isNotNull);
      expect(fetched.degree!.frequency, 1); // Default frequency
      expect(fetched.degree!.importance, 1.0); // Default importance
    });

    test('explainRecall includes activation info', () async {
      final node = MemoryNode(content: 'Test explainability');
      final id = await graph.storeNode(node);

      final explanation = await graph.explainRecall(id, log: false);

      expect(explanation, contains('Node $id recalled'));
      expect(explanation, contains('Activation(recency:'));
      expect(explanation, contains('freq: 1'));
      expect(explanation, contains('imp: 1.0)'));
    });

    test('semanticSearch returns most similar node (ANN)', () async {
      // Store nodes with embeddings
      await graph.storeNodeWithEmbedding(content: 'cat');
      await graph.storeNodeWithEmbedding(content: 'dog');
      await graph.storeNodeWithEmbedding(content: 'elephant');
      await graph.initialize(); // Ensure ANN index is built

      // Query embedding similar to 'dog'
      final queryEmbedding = await graph.embeddingsAdapter.embed('dog');
      final results = await graph.semanticSearch(queryEmbedding, topK: 2);
      expect(results.length, equals(2));
      final nodeContents = results.map((r) => r.node.content).toList();
      expect(nodeContents, contains('dog'));
    });

    test('semanticSearch returns empty if no embeddings', () async {
      // This test ensures that if the vector collection is empty, search returns nothing.
      // We are not storing any nodes with embeddings here.
      await graph.initialize();
      final queryEmbedding = [1.0, 2.0, 3.0, 4.0];
      final results = await graph.semanticSearch(queryEmbedding);
      expect(results, isEmpty);
    });

    test('explainRecall includes semantic distance and provider', () async {
      final id = await graph.storeNodeWithEmbedding(content: 'semantic test');
      await graph.initialize();
      final queryEmbedding =
          await graph.embeddingsAdapter.embed('semantic test');
      final explanation = await graph.explainRecall(id,
          queryEmbedding: queryEmbedding, log: false);
      expect(explanation, contains('Semantic distance:'));
      expect(explanation, contains('provider: mock'));
    });

    test('semanticSearch returns empty for non-matching dimension', () async {
      await graph.storeNodeWithEmbedding(content: 'dim test');
      await graph.initialize();
      // Provide a query embedding with wrong dimension
      final queryEmbedding = [1.0, 2.0]; // Should be 4
      final results = await graph.semanticSearch(queryEmbedding);
      expect(results, isEmpty);
    });

    test('explainRecall handles missing node gracefully', () async {
      final explanation = await graph.explainRecall(99999,
          queryEmbedding: [1, 2, 3, 4], log: false);
      expect(explanation, contains('Node not found'));
    });

    test('store and retrieve edge', () async {
      final n1 = MemoryNode(content: 'A');
      final n2 = MemoryNode(content: 'B');
      final id1 = await graph.storeNode(n1);
      final id2 = await graph.storeNode(n2);
      final edge =
          MemoryEdge(fromNodeId: id1, toNodeId: id2, relation: 'cause');
      await graph.storeEdge(edge);
      final edges = await graph.getEdgesForNode(id1);
      expect(edges, isNotEmpty);
      expect(edges.first.relation, equals('cause'));
    });
  });
}
