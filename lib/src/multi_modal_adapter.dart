import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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

/// Remote multi-modal API adapter (e.g., OpenAI, Gemini).
///
/// Makes HTTP calls to embedding APIs that support text and image inputs.
/// Supports provider-agnostic payload construction via configurable endpoints.
///
/// Example:
/// ```dart
/// final adapter = RemoteMultiModalAdapter(
///   apiUrl: 'https://api.openai.com/v1/embeddings',
///   apiKey: 'sk-...',
///   model: 'text-embedding-3-small',
/// );
/// final embedding = await adapter.embedText('Hello world');
/// ```
class RemoteMultiModalAdapter implements MultiModalEmbeddingsAdapter {
  final String apiUrl;
  final String apiKey;
  final String model;
  final http.Client _client;
  final Duration timeout;
  final int _dimensions;

  RemoteMultiModalAdapter({
    required this.apiUrl,
    required this.apiKey,
    this.model = 'text-embedding-3-small',
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    int dimensions = 768,
  })  : _client = client ?? http.Client(),
        _dimensions = dimensions;

  @override
  int get dimensions => _dimensions;

  @override
  List<Modality> get supportedModalities => [Modality.text, Modality.image];

  @override
  Future<List<double>> embedText(String text) async {
    final body = jsonEncode({
      'model': model,
      'input': text,
    });
    return _post(body);
  }

  @override
  Future<List<double>> embedImage(Uint8List imageBytes) async {
    // Detect MIME type from magic bytes
    final mime = _detectMime(imageBytes);
    final base64 = base64Encode(imageBytes);

    // OpenAI-compatible: data URL
    final dataUrl = 'data:$mime;base64,$base64';

    final body = jsonEncode({
      'model': model,
      'input': dataUrl,
    });
    return _post(body);
  }

  @override
  Future<List<double>> embedAudio(Uint8List audioBytes) async {
    throw UnsupportedError(
      'Audio embedding not supported by this remote adapter. '
      'Use a specialized audio embedding service.',
    );
  }

  @override
  Future<List<double>> embedStructured(Map<String, dynamic> data) async {
    // Convert structured data to text representation
    final text = StructuredDataProcessor.jsonToText(data);
    return embedText(text);
  }

  /// Detect image MIME type from magic bytes.
  String _detectMime(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'image/webp';
    }
    return 'image/png'; // default fallback
  }

  Future<List<double>> _post(String body) async {
    final response = await _client
        .post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Remote embedding API returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // OpenAI format: { "data": [{ "embedding": [...] }] }
    if (json.containsKey('data')) {
      final data = json['data'] as List;
      if (data.isNotEmpty) {
        final entry = data.first as Map<String, dynamic>;
        if (entry.containsKey('embedding')) {
          final values = entry['embedding'] as List;
          return values.map((e) => (e as num).toDouble()).toList();
        }
      }
    }

    // Gemini format: { "embedding": { "values": [...] } }
    if (json.containsKey('embedding')) {
      final emb = json['embedding'] as Map<String, dynamic>;
      if (emb.containsKey('values')) {
        final values = emb['values'] as List;
        return values.map((e) => (e as num).toDouble()).toList();
      }
    }

    throw Exception('Unexpected embedding API response format: ${response.body}');
  }

  /// Release underlying HTTP client.
  void dispose() => _client.close();
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
    // Use StructuredDataProcessor for proper structured-to-text conversion
    final text = StructuredDataProcessor.jsonToText(data);
    return embedText(text);
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
