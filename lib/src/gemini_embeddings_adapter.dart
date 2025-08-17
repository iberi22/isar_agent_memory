import 'dart:async';
import 'embeddings_adapter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini-based implementation of EmbeddingsAdapter for text embeddings.
class GeminiEmbeddingsAdapter implements EmbeddingsAdapter {
  final String apiKey;
  final String model;
  late final GenerativeModel _geminiModel;
  int? _cachedDim;
  final Duration timeout;
  final int maxRetries; // number of retries after the initial attempt
  final Duration retryBaseDelay; // exponential backoff base delay

  GeminiEmbeddingsAdapter({
    required this.apiKey,
    this.model = 'text-embedding-004',
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 300),
  }) {
    _geminiModel = GenerativeModel(
      model: model,
      apiKey: apiKey,
    );
  }

  @override
  final String providerName = 'gemini';

  @override
  int get dimension => _cachedDim ?? 768; // Will update after first embed.

  /// Generates an embedding vector for the given text using Gemini API.
  @override
  Future<List<double>> embed(String text) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await _geminiModel
            .embedContent(Content.text(text))
            .timeout(timeout);
        final embedding = response.embedding;
        if (embedding.values.isEmpty) {
          throw Exception('No embedding returned from Gemini API');
        }
        final vec = embedding.values.map((e) => e.toDouble()).toList();
        _cachedDim = vec.length;
        return vec;
      } on TimeoutException catch (e) {
        if (attempt >= maxRetries) {
          throw Exception(
              'Gemini embeddings request timed out after ${attempt + 1} attempt(s): $e');
        }
        final delay = retryBaseDelay * (1 << attempt);
        await Future.delayed(delay);
        attempt++;
      } catch (e) {
        // Retry on any transient failure; surface after exhausting attempts
        if (attempt >= maxRetries) {
          throw Exception(
              'Gemini embeddings request failed after ${attempt + 1} attempt(s): $e');
        }
        final delay = retryBaseDelay * (1 << attempt);
        await Future.delayed(delay);
        attempt++;
      }
    }
  }
}
