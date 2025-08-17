import 'embeddings_adapter.dart';

/// Composable adapter that tries a primary (on-device) adapter first,
/// and falls back to a secondary (cloud) adapter (e.g., Gemini) on failure.
class FallbackEmbeddingsAdapter implements EmbeddingsAdapter {
  final EmbeddingsAdapter primary;
  final EmbeddingsAdapter fallback;

  /// If true, an empty vector from primary triggers fallback.
  final bool fallbackOnEmpty;

  FallbackEmbeddingsAdapter({
    required this.primary,
    required this.fallback,
    this.fallbackOnEmpty = true,
  });

  @override
  String get providerName =>
      '${primary.providerName}->${fallback.providerName}';

  /// The dimension is determined at runtime from the produced vector.
  /// Consumers should not rely on a fixed dimension here; instead, use
  /// the vector length returned by [embed].
  @override
  int get dimension => 0; // Unknown until first embed

  @override
  Future<List<double>> embed(String text) async {
    try {
      final v = await primary.embed(text);
      if (fallbackOnEmpty && (v.isEmpty)) {
        // Primary returned empty vector; try fallback
        final fv = await fallback.embed(text);
        return fv;
      }
      return v;
    } catch (_) {
      // Any failure in primary triggers fallback
      final fv = await fallback.embed(text);
      return fv;
    }
  }
}
