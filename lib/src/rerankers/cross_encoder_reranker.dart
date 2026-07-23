import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:onnxruntime/onnxruntime.dart';
import '../models/memory_node.dart';
import '../reranking_strategy.dart';
import '../utils/word_piece_tokenizer.dart';
import 'bm25_reranker.dart' show BM25ReRanker;

// =============================================================================
// Exceptions
// =============================================================================

/// Exception thrown by re-ranking operations.
class RerankerException implements Exception {
  final String message;
  final int? statusCode;
  final String? provider;

  RerankerException(this.message, {this.statusCode, this.provider});

  @override
  String toString() => 'RerankerException($provider): $message'
      '${statusCode != null ? ' [HTTP $statusCode]' : ''}';
}

// =============================================================================
// Cross-Encoder Adapter Interface
// =============================================================================

/// Adapter interface for cross-encoder models.
///
/// Implementations should provide actual model inference either locally
/// (ONNX) or remotely (HTTP API).
abstract class CrossEncoderAdapter {
  /// Scores the relevance of a [document] to a [query].
  ///
  /// Returns a score between 0 and 1, where 1 is most relevant.
  Future<double> score(String query, String document);

  /// Batch scoring for better performance.
  Future<List<double>> scoreBatch(String query, List<String> documents);
}

// =============================================================================
// Remote Cross-Encoder via HTTP API
// =============================================================================

/// Preset configurations for common re-ranking providers.
class RerankerProvider {
  final String name;
  final String defaultUrl;
  final String defaultModel;
  final bool needsSigmoid; // true if API returns raw logits

  const RerankerProvider._(
      this.name, this.defaultUrl, this.defaultModel, this.needsSigmoid);

  /// Cohere Rerank API — returns relevance_score in [0, 1].
  static const cohere = RerankerProvider._(
    'cohere',
    'https://api.cohere.com/v2/rerank',
    'rerank-v3.5',
    false,
  );

  /// HuggingFace Inference API — returns raw logits.
  static const huggingface = RerankerProvider._(
    'huggingface',
    'https://api-inference.huggingface.co/models',
    'cross-encoder/ms-marco-MiniLM-L-6-v2',
    true,
  );

  /// Jina Reranker API.
  static const jina = RerankerProvider._(
    'jina',
    'https://api.jina.ai/v1/rerank',
    'jina-reranker-v2-base-multilingual',
    false,
  );

  /// All known presets for iteration.
  static const List<RerankerProvider> known = [cohere, huggingface, jina];
}

/// Cross-encoder adapter that calls a remote HTTP API.
///
/// Supports Cohere, HuggingFace, and Jina re-ranking APIs out of the box.
/// For other providers, pass a custom [apiUrl] and [model].
///
/// Example:
/// ```dart
/// final adapter = RemoteCrossEncoderAdapter.cohere(apiKey: '...');
/// final scores = await adapter.scoreBatch('query', ['doc1', 'doc2']);
/// ```
class RemoteCrossEncoderAdapter implements CrossEncoderAdapter {
  final String apiUrl;
  final String apiKey;
  final String model;
  final http.Client _client;
  final Duration timeout;
  final int maxRetries;
  final bool applySigmoid;

  RemoteCrossEncoderAdapter({
    required this.apiUrl,
    required this.apiKey,
    required this.model,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.applySigmoid = false,
  }) : _client = client ?? http.Client();

  /// Create from a preset [provider].
  factory RemoteCrossEncoderAdapter.fromProvider(
    RerankerProvider provider, {
    required String apiKey,
    String? customUrl,
    String? model,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 2,
  }) {
    return RemoteCrossEncoderAdapter(
      apiUrl: customUrl ?? provider.defaultUrl,
      apiKey: apiKey,
      model: model ?? provider.defaultModel,
      client: client,
      timeout: timeout,
      maxRetries: maxRetries,
      applySigmoid: provider.needsSigmoid,
    );
  }

  /// Convenience constructor for Cohere.
  factory RemoteCrossEncoderAdapter.cohere({
    required String apiKey,
    String? model,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return RemoteCrossEncoderAdapter.fromProvider(
      RerankerProvider.cohere,
      apiKey: apiKey,
      model: model,
      client: client,
      timeout: timeout,
    );
  }

  @override
  Future<double> score(String query, String document) async {
    final scores = await scoreBatch(query, [document]);
    return scores.first;
  }

  @override
  Future<List<double>> scoreBatch(String query, List<String> documents) async {
    if (documents.isEmpty) return [];
    if (query.isEmpty) return List.filled(documents.length, 0.0);

    int attempt = 0;
    while (true) {
      try {
        final response = await _client
            .post(
              Uri.parse(apiUrl),
              headers: _headers(),
              body: jsonEncode(_buildRequest(query, documents)),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return _parseResponse(response.body, documents.length);
        }

        // Retry on 429 or 5xx
        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt >= maxRetries) {
            throw RerankerException(
              'Remote reranker returned HTTP ${response.statusCode}',
              statusCode: response.statusCode,
              provider: apiUrl,
            );
          }
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        throw RerankerException(
          'Remote reranker returned HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
          provider: apiUrl,
        );
      } on TimeoutException {
        if (attempt >= maxRetries) {
          throw RerankerException('Request timed out after $timeout',
              provider: apiUrl);
        }
        attempt++;
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        if (e is RerankerException) rethrow;
        if (attempt >= maxRetries) {
          throw RerankerException('Request failed: $e', provider: apiUrl);
        }
        attempt++;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _buildRequest(String query, List<String> documents) {
    // Cohere-compatible payload (also works with Jina)
    return {
      'model': model,
      'query': query,
      'documents': documents,
      if (documents.length > 5) 'top_n': documents.length,
    };
  }

  List<double> _parseResponse(String body, int expectedCount) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    // Cohere: { "results": [{ "index": 0, "relevance_score": 0.98 }, ...] }
    if (json.containsKey('results')) {
      final results = json['results'] as List;
      final scores = List<double>.filled(expectedCount, 0.0);
      for (final r in results) {
        final idx = r['index'] as int;
        double score = (r['relevance_score'] as num).toDouble();
        if (applySigmoid) score = _sigmoid(score);
        scores[idx] = score;
      }
      return scores;
    }

    // HF Inference API: [{"score": 0.98}, ...] or [0.98, ...]
    if (json.containsKey('score')) {
      final raw = _sigmoid((json['score'] as num).toDouble());
      return [raw];
    }

    // Fallback: try parsing as list of scores
    if (json.values.any((v) => v is List)) {
      final list = json.values.firstWhere((v) => v is List) as List;
      if (list.isNotEmpty && list.first is num) {
        return list.map((e) {
          final s = (e as num).toDouble();
          return applySigmoid ? _sigmoid(s) : s;
        }).toList();
      }
    }

    throw RerankerException(
      'Unexpected response format: $body',
      provider: apiUrl,
    );
  }

  double _sigmoid(double x) => 1.0 / (1.0 + _exp(-x));
  double _exp(double x) {
    // Manual exp implementation to avoid dart:math import for this one use
    // Uses Taylor series approximation: exp(x) = sum(x^n / n!)
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  /// Release underlying HTTP client.
  void dispose() => _client.close();
}

// =============================================================================
// Local Cross-Encoder (ONNX)
// =============================================================================

/// A local cross-encoder adapter that runs entirely on-device using ONNX Runtime.
///
/// Designed to work with BERT-based cross-encoder models.
/// Requires the ONNX model file and vocabulary file locally.
class LocalCrossEncoderAdapter implements CrossEncoderAdapter {
  final String modelPath;
  final String vocabPath;
  final int dimension;

  late final OrtSession _session;
  late final WordPieceTokenizer _tokenizer;
  bool _initialized = false;

  // Cache vocabulary to avoid reading the file multiple times
  static Map<String, int>? _cachedVocab;

  LocalCrossEncoderAdapter({
    required this.modelPath,
    required this.vocabPath,
    this.dimension = 384,
  });

  /// Initializes the vocabulary tokenizer and the ONNX runtime session.
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Load Vocab
    if (_cachedVocab == null) {
      final vocabFile = File(vocabPath);
      if (!await vocabFile.exists()) {
        throw Exception('Vocabulary file not found at $vocabPath');
      }
      final lines = await vocabFile.readAsLines();
      _cachedVocab = {
        for (var i = 0; i < lines.length; i++) lines[i].trim(): i,
      };
    }

    _tokenizer = WordPieceTokenizer(vocab: _cachedVocab!);

    // 2. Init ONNX Session
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();

    _session = OrtSession.fromFile(File(modelPath), sessionOptions);

    _initialized = true;
  }

  /// Releases local ONNX session resources.
  void release() {
    if (_initialized) {
      _session.release();
      OrtEnv.instance.release();
      _initialized = false;
    }
  }

  /// Releases resources (alias for release).
  void dispose() {
    release();
  }

  @override
  Future<double> score(String query, String document) async {
    final scores = await scoreBatch(query, [document]);
    return scores.first;
  }

  @override
  Future<List<double>> scoreBatch(String query, List<String> documents) async {
    if (documents.isEmpty) return [];
    if (query.isEmpty) return List.filled(documents.length, 0.0);

    if (!_initialized) {
      await initialize();
    }

    final batchSize = documents.length;

    // 1. Tokenize query and each document
    final qTokens = _tokenizer.tokenize(query);
    final qIds = qTokens.sublist(1, qTokens.length - 1);

    final allCombinedIds = <List<int>>[];
    final allTokenTypeIds = <List<int>>[];

    for (final doc in documents) {
      final dTokens = _tokenizer.tokenize(doc);
      final dIds = dTokens.sublist(1, dTokens.length - 1);

      final combinedIds = [
        _tokenizer.clsTokenId,
        ...qIds,
        _tokenizer.sepTokenId,
        ...dIds,
        _tokenizer.sepTokenId,
      ];
      allCombinedIds.add(combinedIds);

      final tokenTypeIds = [
        ...List.filled(1 + qIds.length + 1, 0),
        ...List.filled(dIds.length + 1, 1),
      ];
      allTokenTypeIds.add(tokenTypeIds);
    }

    // 2. Pad to max sequence length in batch
    int maxSeqLen = 0;
    for (final ids in allCombinedIds) {
      if (ids.length > maxSeqLen) {
        maxSeqLen = ids.length;
      }
    }

    final paddedInputIds = <int>[];
    final paddedAttentionMask = <int>[];
    final paddedTokenTypeIds = <int>[];

    for (int i = 0; i < batchSize; i++) {
      final ids = allCombinedIds[i];
      final typeIds = allTokenTypeIds[i];

      final paddingLength = maxSeqLen - ids.length;

      paddedInputIds.addAll(ids);
      paddedInputIds.addAll(List.filled(paddingLength, _tokenizer.padTokenId));

      paddedAttentionMask.addAll(List.filled(ids.length, 1));
      paddedAttentionMask.addAll(List.filled(paddingLength, 0));

      paddedTokenTypeIds.addAll(typeIds);
      paddedTokenTypeIds.addAll(List.filled(paddingLength, 0)); // Pad with 0s
    }

    // 3. Prepare Inputs
    final shape = [batchSize, maxSeqLen];
    final inputIdsInt64 = Int64List.fromList(paddedInputIds);
    final attentionMaskInt64 = Int64List.fromList(paddedAttentionMask);
    final tokenTypeIdsInt64 = Int64List.fromList(paddedTokenTypeIds);

    final inputIdsOrt = OrtValueTensor.createTensorWithDataList(inputIdsInt64, shape);
    final attentionMaskOrt = OrtValueTensor.createTensorWithDataList(attentionMaskInt64, shape);
    final tokenTypeIdsOrt = OrtValueTensor.createTensorWithDataList(tokenTypeIdsInt64, shape);

    final inputs = {
      'input_ids': inputIdsOrt,
      'attention_mask': attentionMaskOrt,
      'token_type_ids': tokenTypeIdsOrt,
    };

    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;

    try {
      // 4. Run Inference
      outputs = _session.run(runOptions, inputs);

      if (outputs.isEmpty || outputs.first == null) {
        throw Exception('No output returned from ONNX cross-encoder model.');
      }

      final outputValue = outputs.first!;
      final outputTensor = outputValue as OrtValueTensor;
      final rawValue = outputTensor.value;

      final scores = <double>[];

      // Robustly extract logits from nested / flattened structures
      if (rawValue is List) {
        for (int i = 0; i < batchSize; i++) {
          if (i >= rawValue.length) {
            scores.add(0.0);
            continue;
          }
          final item = rawValue[i];
          double logit = 0.0;
          if (item is List) {
            if (item.isNotEmpty) {
              final subItem = item.first;
              if (subItem is List) {
                // E.g. [batch_size, seq_len, dim] -> take first token's first value
                if (subItem.isNotEmpty) {
                  logit = (subItem.first as num).toDouble();
                }
              } else if (subItem is num) {
                // E.g. [batch_size, 1] or [batch_size, 2]
                if (item.length >= 2) {
                  logit = (item[1] as num).toDouble();
                } else {
                  logit = (subItem as num).toDouble();
                }
              }
            }
          } else if (item is num) {
            // Flat list
            logit = item.toDouble();
          }
          scores.add(_sigmoid(logit));
        }
      } else {
        throw Exception('Unexpected ONNX output format: ${rawValue.runtimeType}');
      }

      return scores;
    } finally {
      // Clean up resources
      for (final entry in inputs.entries) {
        entry.value.release();
      }
      runOptions.release();
      if (outputs != null) {
        for (final v in outputs) {
          v?.release();
        }
      }
    }
  }

  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
}

// =============================================================================
// CrossEncoderReranker — wraps CrossEncoderAdapter as ReRankingStrategy
// =============================================================================

/// Cross-encoder based re-ranking strategy.
///
/// Uses a [CrossEncoderAdapter] to score query-document pairs directly,
/// providing more accurate relevance judgments than embedding-distance methods.
///
/// Since cross-encoder inference is async, this class implements
/// [ReRankingStrategy] with a [FutureOr] return.
class CrossEncoderReranker implements ReRankingStrategy {
  final CrossEncoderAdapter encoder;
  final double minScore;

  CrossEncoderReranker({
    required this.encoder,
    this.minScore = 0.0,
  });

  @override
  Future<List<({MemoryNode node, double score})>> reRank(
    List<({MemoryNode node, double score})> results, {
    String? query,
  }) async {
    if (results.isEmpty || query == null || query.isEmpty) return results;

    final documents = results.map((r) => r.node.content).toList();
    final scores = await encoder.scoreBatch(query, documents);

    final scored = <({MemoryNode node, double score})>[];
    for (int i = 0; i < results.length; i++) {
      if (i < scores.length && scores[i] >= minScore) {
        scored.add((node: results[i].node, score: scores[i]));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }
}

// =============================================================================
// Hybrid Reranker — weighted combination of multiple strategies
// =============================================================================

/// A re-ranker with an associated weight for use in [HybridReranker].
class WeightedReranker {
  final ReRankingStrategy reranker;
  final double weight;

  WeightedReranker({required this.reranker, this.weight = 1.0});
}

/// Combines multiple re-ranking strategies using weighted score fusion.
class HybridReranker implements ReRankingStrategy {
  final List<WeightedReranker> rerankers;
  final bool normalizeScores;

  HybridReranker({
    required this.rerankers,
    this.normalizeScores = true,
  });

  @override
  Future<List<({MemoryNode node, double score})>> reRank(
    List<({MemoryNode node, double score})> candidates, {
    String? query,
  }) async {
    if (candidates.isEmpty || rerankers.isEmpty) return candidates;

    // Collect scores from all rerankers
    final nodeIds = candidates.map((c) => c.node.id).toSet();
    final allScores = <int, List<double>>{};

    for (final weighted in rerankers) {
      final reranked = await weighted.reranker.reRank(candidates, query: query);

      // Build a map of id → score for this reranker
      final scoreMap = <int, double>{};
      for (final r in reranked) {
        scoreMap[r.node.id] = r.score;
      }

      // Normalize scores across this reranker's output if requested
      final values = scoreMap.values.toList();
      double minV = 0, maxV = 1;
      if (normalizeScores && values.isNotEmpty) {
        minV = values.reduce((a, b) => a < b ? a : b);
        maxV = values.reduce((a, b) => a > b ? a : b);
      }
      final range = maxV - minV;

      for (final id in nodeIds) {
        final raw = scoreMap[id] ?? 0.0;
        final normalized =
            (range > 0 && normalizeScores) ? (raw - minV) / range : raw;
        allScores.putIfAbsent(id, () => []);
        allScores[id]!.add(normalized * weighted.weight);
      }
    }

    // Combine scores
    final totalWeight = rerankers.fold<double>(0, (s, r) => s + r.weight);
    final combined = <({MemoryNode node, double score})>[];

    final nodeMap = <int, MemoryNode>{};
    for (final c in candidates) {
      nodeMap[c.node.id] = c.node;
    }

    for (final id in nodeIds) {
      final node = nodeMap[id];
      if (node == null) continue;
      final scores = allScores[id] ?? [0.0];
      final avg = scores.reduce((a, b) => a + b) / totalWeight;
      combined.add((node: node, score: avg));
    }

    combined.sort((a, b) => b.score.compareTo(a.score));
    return combined;
  }
}

// =============================================================================
// MMR Reranker (kept for backward compat — delegates to mmr_reranker.dart)
// =============================================================================

/// Distance function type for MMR.
typedef DistanceFunction = double Function(Float32List a, Float32List b);

/// Cosine distance implementation.
double cosineDistance(Float32List a, Float32List b) {
  if (a.length != b.length) {
    throw ArgumentError('Vectors must have same length');
  }
  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0.0 || normB == 0.0) return 1.0;
  final similarity = dotProduct / (_sqrt(normA) * _sqrt(normB));
  return 1.0 - similarity;
}

double _sqrt(double x) {
  if (x < 0) return 0;
  double guess = x / 2;
  for (int i = 0; i < 10; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
