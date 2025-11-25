import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

class ThrowingLocalAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'local-throw';
  @override
  int get dimension => 0;
  @override
  Future<List<double>> embed(String text) async =>
      throw Exception('local failed');
}

bool _shouldSkipGeminiIntegration() {
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
  final run = Platform.environment['RUN_GEMINI_TESTS'] ?? '';
  final enabled = run == '1' || run.toLowerCase() == 'true';
  return apiKey.isEmpty || !enabled;
}

// In-memory VectorIndex stub for tests (avoids native libs and plugins)
class InMemoryVectorIndex implements VectorIndex {
  final String _namespace;
  final bool _normalize;
  final VectorMetric _metric;
  final Map<String, Float32List> _store = {};

  InMemoryVectorIndex({
    String namespace = 'test',
    bool normalize = true,
    VectorMetric metric = VectorMetric.cosine,
  })  : _namespace = namespace,
        _normalize = normalize,
        _metric = metric;

  @override
  String get provider => 'in-memory';
  @override
  String get namespace => _namespace;
  @override
  bool get normalize => _normalize;
  @override
  VectorMetric get metric => _metric;

  @override
  Future<void> addDocument(
    String id,
    String content,
    Float32List vector,
  ) async {
    _store[id] = vector;
  }

  @override
  Future<void> removeDocument(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<VectorSearchResult>> search(
    Float32List query, {
    int topK = 5,
  }) async {
    // naive dot-product score
    final scores = <String, double>{};
    _store.forEach((id, vec) {
      final len = (query.length < vec.length) ? query.length : vec.length;
      var s = 0.0;
      for (var i = 0; i < len; i++) {
        s += query[i] * vec[i];
      }
      scores[id] = s;
    });
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(topK)
        .map((e) => VectorSearchResult(id: e.key, score: e.value))
        .toList();
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<void> load() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fallback -> Gemini integration (skips without GEMINI_API_KEY)', () {
    test(
      'falls back to Gemini when primary fails',
      () async {
        final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';

        final dir = Directory('./testdb_fb_gem');
        await dir.create(recursive: true);
        final isar = await Isar.open([
          MemoryNodeSchema,
          MemoryEdgeSchema,
        ], directory: dir.path);

        final adapter = FallbackEmbeddingsAdapter(
          primary: ThrowingLocalAdapter(),
          fallback: GeminiEmbeddingsAdapter(apiKey: apiKey),
        );
        final graph = MemoryGraph(
          isar,
          embeddingsAdapter: adapter,
          index: InMemoryVectorIndex(namespace: 'fb'),
        );

        final id = await graph.storeNodeWithEmbedding(
          content: 'fallback to gemini',
        );
        expect(id, greaterThan(0));
        final node = await graph.getNode(id);
        expect(node, isNotNull);
        expect(node!.embedding, isNotNull);
        expect(node.embedding!.vector.length, greaterThan(0));

        await isar.close(deleteFromDisk: true);
      },
      skip: _shouldSkipGeminiIntegration()
          ? 'Set GEMINI_API_KEY and RUN_GEMINI_TESTS=1 to run this test'
          : null,
    );
  });
}
