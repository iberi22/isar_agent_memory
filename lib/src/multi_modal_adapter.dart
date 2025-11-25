import 'dart:typed_data';
import 'embeddings_adapter.dart';

/// Multi-modal embeddings adapter for different data types.
///
/// Supports text, images, audio, and structured data.
abstract class MultiModalEmbeddingsAdapter {
  /// Embeds text content.
  Future<List<double>> embedText(String text);

  /// Embeds image data.
  Future<List<double>> embedImage(Uint8List imageBytes);

  /// Embeds audio data.
  Future<List<double>> embedAudio(Uint8List audioBytes);

  /// Embeds structured data (JSON, tables, etc.).
  Future<List<double>> embedStructured(Map<String, dynamic> data);

  /// Gets the dimension of embeddings produced.
  int get dimensions;

  /// Gets supported modalities.
  List<Modality> get supportedModalities;
}

/// Supported data modalities.
enum Modality {
  text,
  image,
  audio,
  structured,
  code,
  video,
}

/// CLIP-style multi-modal adapter (text + image).
///
/// Uses shared embedding space for text and images.
class CLIPAdapter implements MultiModalEmbeddingsAdapter {
  final String modelPath;
  final int _dimensions;

  CLIPAdapter({
    required this.modelPath,
    int dimensions = 512,
  }) : _dimensions = dimensions;

  @override
  int get dimensions => _dimensions;

  @override
  List<Modality> get supportedModalities => [Modality.text, Modality.image];

  @override
  Future<List<double>> embedText(String text) async {
    // TODO: Implement CLIP text encoder
    // Would use ONNX runtime or remote API
    throw UnimplementedError('CLIP text encoding requires model integration');
  }

  @override
  Future<List<double>> embedImage(Uint8List imageBytes) async {
    // TODO: Implement CLIP image encoder
    // Would process image through vision transformer
    throw UnimplementedError('CLIP image encoding requires model integration');
  }

  @override
  Future<List<double>> embedAudio(Uint8List audioBytes) async {
    throw UnsupportedError('CLIP does not support audio modality');
  }

  @override
  Future<List<double>> embedStructured(Map<String, dynamic> data) async {
    // Fallback: convert to text representation
    return embedText(data.toString());
  }
}

/// ImageBind-style adapter for all modalities.
///
/// Projects different modalities into a shared embedding space.
class ImageBindAdapter implements MultiModalEmbeddingsAdapter {
  final String modelPath;
  final int _dimensions;

  ImageBindAdapter({
    required this.modelPath,
    int dimensions = 1024,
  }) : _dimensions = dimensions;

  @override
  int get dimensions => _dimensions;

  @override
  List<Modality> get supportedModalities => [
        Modality.text,
        Modality.image,
        Modality.audio,
        Modality.video,
      ];

  @override
  Future<List<double>> embedText(String text) async {
    throw UnimplementedError(
        'ImageBind text encoding requires model integration');
  }

  @override
  Future<List<double>> embedImage(Uint8List imageBytes) async {
    throw UnimplementedError(
        'ImageBind image encoding requires model integration');
  }

  @override
  Future<List<double>> embedAudio(Uint8List audioBytes) async {
    throw UnimplementedError(
        'ImageBind audio encoding requires model integration');
  }

  @override
  Future<List<double>> embedStructured(Map<String, dynamic> data) async {
    return embedText(_structuredToText(data));
  }

  String _structuredToText(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

/// Code embeddings adapter using CodeBERT or similar.
class CodeEmbeddingsAdapter implements EmbeddingsAdapter {
  @override
  String get providerName => 'CodeBERT';
  final String modelPath;
  final int _dimensions;

  CodeEmbeddingsAdapter({
    required this.modelPath,
    int dimensions = 768,
  }) : _dimensions = dimensions;

  @override
  int get dimension => _dimensions;

  @override
  Future<List<double>> embed(String code) async {
    // TODO: Implement CodeBERT or GraphCodeBERT
    throw UnimplementedError('Code embedding requires model integration');
  }

  Future<List<List<double>>> embedBatch(List<String> texts) async {
    return Future.wait(texts.map((t) => embed(t)));
  }
}

/// Remote multi-modal API adapter (e.g., OpenAI, Cohere).
class RemoteMultiModalAdapter implements MultiModalEmbeddingsAdapter {
  final String apiUrl;
  final String apiKey;
  final String model;
  final int _dimensions;

  RemoteMultiModalAdapter({
    required this.apiUrl,
    required this.apiKey,
    this.model = 'clip-vit-base-patch32',
    int dimensions = 512,
  }) : _dimensions = dimensions;

  @override
  int get dimensions => _dimensions;

  @override
  List<Modality> get supportedModalities => [Modality.text, Modality.image];

  @override
  Future<List<double>> embedText(String text) async {
    // TODO: Implement HTTP API call
    throw UnimplementedError('Remote API integration required');
  }

  @override
  Future<List<double>> embedImage(Uint8List imageBytes) async {
    // TODO: Implement HTTP API call with image upload
    throw UnimplementedError('Remote API integration required');
  }

  @override
  Future<List<double>> embedAudio(Uint8List audioBytes) async {
    throw UnsupportedError('Audio not supported by this API');
  }

  @override
  Future<List<double>> embedStructured(Map<String, dynamic> data) async {
    return embedText(data.toString());
  }
}

/// Hybrid adapter that delegates to specialized adapters per modality.
class HybridMultiModalAdapter implements MultiModalEmbeddingsAdapter {
  final EmbeddingsAdapter textAdapter;
  final MultiModalEmbeddingsAdapter? imageAdapter;
  final MultiModalEmbeddingsAdapter? audioAdapter;
  final int _dimensions;

  HybridMultiModalAdapter({
    required this.textAdapter,
    this.imageAdapter,
    this.audioAdapter,
    required int dimensions,
  }) : _dimensions = dimensions;

  @override
  int get dimensions => _dimensions;

  @override
  List<Modality> get supportedModalities {
    final modalities = [Modality.text];
    if (imageAdapter != null) modalities.add(Modality.image);
    if (audioAdapter != null) modalities.add(Modality.audio);
    return modalities;
  }

  @override
  Future<List<double>> embedText(String text) async {
    return textAdapter.embed(text);
  }

  @override
  Future<List<double>> embedImage(Uint8List imageBytes) async {
    if (imageAdapter == null) {
      throw UnsupportedError('Image embedding not configured');
    }
    return imageAdapter!.embedImage(imageBytes);
  }

  @override
  Future<List<double>> embedAudio(Uint8List audioBytes) async {
    if (audioAdapter == null) {
      throw UnsupportedError('Audio embedding not configured');
    }
    return audioAdapter!.embedAudio(audioBytes);
  }

  @override
  Future<List<double>> embedStructured(Map<String, dynamic> data) async {
    // Convert to text and use text adapter
    return embedText(data.toString());
  }
}

/// Structured data processor for table embeddings.
class StructuredDataProcessor {
  /// Converts tabular data to text representation for embedding.
  static String tableToText(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';

    final columns = rows.first.keys.toList();
    final buffer = StringBuffer();

    // Header
    buffer.writeln(columns.join(' | '));
    buffer.writeln(columns.map((c) => '-' * c.length).join('-|-'));

    // Rows
    for (final row in rows) {
      buffer.writeln(columns.map((c) => row[c]?.toString() ?? '').join(' | '));
    }

    return buffer.toString();
  }

  /// Converts JSON to structured text for embedding.
  static String jsonToText(Map<String, dynamic> json, {int indent = 0}) {
    final buffer = StringBuffer();
    final prefix = '  ' * indent;

    for (final entry in json.entries) {
      if (entry.value is Map) {
        buffer.writeln('$prefix${entry.key}:');
        buffer.write(jsonToText(entry.value as Map<String, dynamic>,
            indent: indent + 1));
      } else if (entry.value is List) {
        buffer.writeln('$prefix${entry.key}: [${entry.value.join(", ")}]');
      } else {
        buffer.writeln('$prefix${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// Extracts key-value pairs for embedding.
  static List<String> extractKeyPhrases(Map<String, dynamic> data) {
    final phrases = <String>[];

    void extract(Map<String, dynamic> map, String prefix) {
      for (final entry in map.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

        if (entry.value is Map) {
          extract(entry.value as Map<String, dynamic>, key);
        } else if (entry.value is List) {
          phrases.add('$key: ${entry.value.join(", ")}');
        } else {
          phrases.add('$key: ${entry.value}');
        }
      }
    }

    extract(data, '');
    return phrases;
  }
}
