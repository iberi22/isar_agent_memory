/// Abstract interface for embedding providers (Gemini, OpenAI, local, etc.)
abstract class EmbeddingsAdapter {
  /// Generates an embedding vector for the given text.
  Future<List<double>> embed(String text);

  /// Optionally, provider/model name.
  String get providerName;
}
