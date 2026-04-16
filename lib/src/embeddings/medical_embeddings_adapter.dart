import 'package:isar_agent_memory/src/embeddings_adapter.dart';
import 'package:isar_agent_memory/src/utils/medical_tokenizer.dart';

/// An [EmbeddingsAdapter] decorator that enhances medical text processing.
///
/// It uses [MedicalTokenizer] to expand medical abbreviations (Spanish/English)
/// before passing the text to the underlying adapter.
class MedicalEmbeddingsAdapter implements EmbeddingsAdapter {
  /// The underlying embeddings adapter.
  final EmbeddingsAdapter inner;

  /// The tokenizer used for medical text expansion.
  final MedicalTokenizer tokenizer;

  /// Creates a [MedicalEmbeddingsAdapter] wrapping an [inner] adapter.
  MedicalEmbeddingsAdapter(this.inner, {MedicalTokenizer? tokenizer})
      : tokenizer = tokenizer ?? MedicalTokenizer();

  @override
  int get dimension => inner.dimension;

  @override
  String get providerName => 'medical_enhanced(${inner.providerName})';

  /// Generates an embedding by first expanding medical abbreviations.
  @override
  Future<List<double>> embed(String text) async {
    final expandedText = tokenizer.expandAbbreviations(text);
    return inner.embed(expandedText);
  }

  /// Generates a normalized embedding for medical domain text.
  ///
  /// This implementation expands abbreviations and then uses the inner adapter's
  /// [medicalNormalized] if available, or its [embed] method.
  @override
  Future<List<double>> medicalNormalized(String text) async {
    final expandedText = tokenizer.expandAbbreviations(text);
    return inner.medicalNormalized(expandedText);
  }
}
