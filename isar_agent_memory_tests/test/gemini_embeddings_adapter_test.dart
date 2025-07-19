import 'dart:io';

import 'package:test/test.dart';
import 'package:isar_agent_memory/src/gemini_embeddings_adapter.dart';

void main() {
  group('GeminiEmbeddingsAdapter', () {
    // Read API key from environment variables for testing.
    final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    final adapter = GeminiEmbeddingsAdapter(apiKey: apiKey);

    test(
      'returns embedding for valid text',
      () async {
        final embedding = await adapter.embed('Hello world!');
        expect(embedding, isA<List<double>>());
        expect(embedding.length, greaterThan(0));
      },
      skip: apiKey.isEmpty
          ? 'No Gemini API key provided, skipping real API test.'
          : null,
    );

    test('throws on invalid API key', () async {
      final badAdapter = GeminiEmbeddingsAdapter(apiKey: 'INVALID_KEY');
      expect(
        () async => await badAdapter.embed('test'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
