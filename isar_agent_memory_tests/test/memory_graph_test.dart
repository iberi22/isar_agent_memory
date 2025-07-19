import 'dart:io';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';
import 'package:isar_agent_memory/src/embeddings_adapter.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/services.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create a dummy directory for path_provider mock
  Directory('./test_app_documents').createSync(recursive: true);

  // Mock path_provider for tests
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return './test_app_documents'; // Return a dummy path for testing
          }
          return null;
        },
      );
  group('MemoryGraph Tests', () {
    late Isar isar;
    late MemoryGraph graph;
    const testDbPath = './testdb';

    setUpAll(() async {
      // Workaround to manually copy the Isar native binary for the test environment.
      try {
        await Isar.initializeIsarCore();
      } catch (e) {
        if (e.toString().contains('Failed to load dynamic library')) {
          stderr.writeln(
            'Isar binary not found. Attempting to copy it manually...',
          );
          final packageConfig = File('.dart_tool/package_config.json');
          final content = await packageConfig.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final isarFlutterLibsEntry = (json['packages'] as List).firstWhere(
            (p) => p['name'] == 'isar_flutter_libs',
            orElse: () => null,
          );

          if (isarFlutterLibsEntry == null) {
            throw Exception(
              'isar_flutter_libs package not found in .dart_tool/package_config.json',
            );
          }

          final libPathUri = Uri.parse(
            isarFlutterLibsEntry['rootUri'] as String,
          );
          final libPath = File.fromUri(libPathUri).path;
          final isarBinary = File(p.join(libPath, 'windows', 'isar.dll'));

          if (!await isarBinary.exists()) {
            throw Exception('isar.dll not found at ${isarBinary.path}');
          }

          await isarBinary.copy('./isar.dll');
          stderr.writeln(
            'Successfully copied isar.dll, retrying initialization...',
          );
          await Isar.initializeIsarCore();
        } else {
          rethrow;
        }
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
      addTearDown(() async {
        graph.clearVectorCollection();
      });
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
      final queryEmbedding = await graph.embeddingsAdapter.embed(
        'semantic test',
      );
      final explanation = await graph.explainRecall(
        id,
        queryEmbedding: queryEmbedding,
        log: false,
      );
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
      final explanation = await graph.explainRecall(
        99999,
        queryEmbedding: [1, 2, 3, 4],
        log: false,
      );
      expect(explanation, contains('Node not found'));
    });

    test('store and retrieve edge', () async {
      final n1 = MemoryNode(content: 'A');
      final n2 = MemoryNode(content: 'B');
      final id1 = await graph.storeNode(n1);
      final id2 = await graph.storeNode(n2);
      final edge = MemoryEdge(
        fromNodeId: id1,
        toNodeId: id2,
        relation: 'cause',
      );
      await graph.storeEdge(edge);
      final edges = await graph.getEdgesForNode(id1);
      expect(edges, isNotEmpty);
      expect(edges.first.relation, equals('cause'));
    });
  });
}
