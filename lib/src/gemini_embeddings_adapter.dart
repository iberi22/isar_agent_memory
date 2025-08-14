import 'embeddings_adapter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini-based implementation of EmbeddingsAdapter for text embeddings.
class GeminiEmbeddingsAdapter implements EmbeddingsAdapter {
  final String apiKey;
  final String model;
  late final GenerativeModel _geminiModel;

  GeminiEmbeddingsAdapter(
      {required this.apiKey, this.model = 'embedding-001'}) {
    _geminiModel = GenerativeModel(
      model: model,
      apiKey: apiKey,
    );
  }

  @override
  final String providerName = 'gemini';

  @override
  int get dimension => 768; // Gemini text-embedding-004 has 768 dimensions.

  /// Generates an embedding vector for the given text using Gemini API.
  @override
  Future<List<double>> embed(String text) async {
    final response = await _geminiModel.embedContent(Content.text(text));
    final embedding = response.embedding;
    if (embedding.values.isEmpty) {
      throw Exception('No embedding returned from Gemini API');
    }
    return embedding.values.map((e) => e.toDouble()).toList();
  }
}
