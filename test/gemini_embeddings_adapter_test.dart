import 'package:test/test.dart';
import 'package:isar_agent_memory/src/gemini_embeddings_adapter.dart';

void main() {
  group('GeminiEmbeddingsAdapter', () {
    // NOTE: Set your Gemini API key as an environment variable or inject here for real test
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final adapter = GeminiEmbeddingsAdapter(apiKey: apiKey);

    test('returns embedding for valid text', () async {
      if (apiKey.isEmpty) {
        print('No Gemini API key provided, skipping real API test.');
        return;
      }
      final embedding = await adapter.embed('Hello world!');
      expect(embedding, isA<List<double>>());
      expect(embedding.length, greaterThan(0));
    });

    test('throws on invalid API key', () async {
      final badAdapter = GeminiEmbeddingsAdapter(apiKey: 'INVALID_KEY');
      expect(
        () async => await badAdapter.embed('test'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
