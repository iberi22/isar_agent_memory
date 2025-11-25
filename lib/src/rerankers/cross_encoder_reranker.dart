import 'dart:typed_data';
import '../models/memory_node.dart';

/// Result with score.
typedef ScoredNode = ({MemoryNode node, double score, double distance});

/// Cross-Encoder based re-ranking strategy.
///
/// Uses a more sophisticated model to re-rank results by comparing
/// query-document pairs directly, rather than just using embedding distances.
class CrossEncoderReranker {
  final CrossEncoderAdapter encoder;
  final double minScore;

  CrossEncoderReranker({
    required this.encoder,
    this.minScore = 0.0,
  });

  Future<List<ScoredNode>> rerank({
    required String query,
    required List<ScoredNode> candidates,
    int? topK,
  }) async {
    if (candidates.isEmpty) return [];

    // Score each query-document pair
    final scoredResults = <ScoredNode>[];

    for (final candidate in candidates) {
      final score = await encoder.score(query, candidate.node.content);

      if (score >= minScore) {
        scoredResults.add((
          node: candidate.node,
          score: score,
          distance: 1.0 - score, // Convert score to distance
        ));
      }
    }

    // Sort by score (descending)
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    return topK != null ? scoredResults.take(topK).toList() : scoredResults;
  }
}

/// Adapter interface for cross-encoder models.
///
/// Implementations should provide actual model inference.
abstract class CrossEncoderAdapter {
  /// Scores the relevance of a document to a query.
  ///
  /// Returns a score between 0 and 1, where 1 is most relevant.
  Future<double> score(String query, String document);

  /// Batch scoring for better performance.
  Future<List<double>> scoreBatch(String query, List<String> documents);
}

/// Implementation using a local ONNX cross-encoder model.
class LocalCrossEncoderAdapter implements CrossEncoderAdapter {
  // TODO: Add ONNX runtime integration
  final String modelPath;
  final String tokenizerPath;

  LocalCrossEncoderAdapter({
    required this.modelPath,
    required this.tokenizerPath,
  });

  @override
  Future<double> score(String query, String document) async {
    // Placeholder implementation
    // In production, this would:
    // 1. Tokenize query + document pair
    // 2. Run through ONNX model
    // 3. Return relevance score

    throw UnimplementedError(
      'Local cross-encoder requires ONNX runtime integration. '
      'Use RemoteCrossEncoderAdapter for API-based inference.',
    );
  }

  @override
  Future<List<double>> scoreBatch(String query, List<String> documents) async {
    // Batch inference would be more efficient
    throw UnimplementedError('Batch scoring not yet implemented');
  }
}

/// Implementation using a remote API (e.g., Cohere, HuggingFace).
class RemoteCrossEncoderAdapter implements CrossEncoderAdapter {
  final String apiUrl;
  final String apiKey;
  final String model;

  RemoteCrossEncoderAdapter({
    required this.apiUrl,
    required this.apiKey,
    this.model = 'cross-encoder/ms-marco-MiniLM-L-6-v2',
  });

  @override
  Future<double> score(String query, String document) async {
    final scores = await scoreBatch(query, [document]);
    return scores.first;
  }

  @override
  Future<List<double>> scoreBatch(String query, List<String> documents) async {
    // TODO: Implement actual API call
    // Example with Cohere Rerank API or HuggingFace Inference API

    throw UnimplementedError(
      'Remote cross-encoder requires HTTP client implementation. '
      'Please provide API endpoint configuration.',
    );
  }
}

/// Hybrid re-ranker combining multiple strategies.
///
/// Uses a weighted combination of different re-ranking approaches.
class HybridReranker {
  final List<WeightedReranker> rerankers;

  /// Whether to normalize scores before combining.
  final bool normalizeScores;

  HybridReranker({
    required this.rerankers,
    this.normalizeScores = true,
  });

  Future<List<ScoredNode>> rerank({
    required String query,
    required List<ScoredNode> candidates,
    int? topK,
  }) async {
    if (candidates.isEmpty) return [];
    if (rerankers.isEmpty) return candidates;

    // Collect scores from all rerankers
    final allScores = <String, List<double>>{};

    for (final weighted in rerankers) {
      final reranked = await weighted.reranker.rerank(
        query: query,
        candidates: candidates,
      );

      // Store scores by node ID
      for (int i = 0; i < reranked.length; i++) {
        final nodeId = reranked[i].node.id.toString();
        allScores.putIfAbsent(nodeId, () => []);
        allScores[nodeId]!.add(reranked[i].score * weighted.weight);
      }
    }

    // Combine scores
    final combined = <ScoredNode>[];
    final totalWeight = rerankers.fold<double>(0, (sum, r) => sum + r.weight);

    for (final candidate in candidates) {
      final nodeId = candidate.node.id.toString();
      final scores = allScores[nodeId] ?? [0.0];
      final avgScore = scores.reduce((a, b) => a + b) / totalWeight;

      combined.add((
        node: candidate.node,
        score: avgScore,
        distance: 1.0 - avgScore,
      ));
    }

    // Sort by combined score
    combined.sort((a, b) => b.score.compareTo(a.score));

    return topK != null ? combined.take(topK).toList() : combined;
  }
}

/// A re-ranker with an associated weight.
class WeightedReranker {
  final dynamic reranker;
  final double weight;

  WeightedReranker({
    required this.reranker,
    this.weight = 1.0,
  });
}

/// MMR (Maximal Marginal Relevance) re-ranker for diversity.
///
/// Balances relevance with diversity to avoid redundant results.
class MMRReranker {
  /// Lambda parameter: 1 = only relevance, 0 = only diversity.
  final double lambda;

  /// Distance function for measuring diversity between nodes.
  final DistanceFunction distanceFunction;

  MMRReranker({
    this.lambda = 0.7,
    this.distanceFunction = cosineDistance,
  });

  Future<List<ScoredNode>> rerank({
    required String query,
    required List<ScoredNode> candidates,
    int? topK,
  }) async {
    if (candidates.isEmpty) return [];

    final k = topK ?? candidates.length;
    final selected = <ScoredNode>[];
    final remaining = List<ScoredNode>.from(candidates);

    // Select first item (most relevant)
    selected.add(remaining.removeAt(0));

    // Iteratively select items that maximize MMR
    while (selected.length < k && remaining.isNotEmpty) {
      double maxMMR = double.negativeInfinity;
      int maxIndex = 0;

      for (int i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];

        // Relevance score
        final relevance = candidate.score;

        // Maximum similarity to already selected items
        double maxSimilarity = 0.0;
        for (final selectedNode in selected) {
          final similarity = _calculateSimilarity(
            candidate.node,
            selectedNode.node,
          );
          maxSimilarity =
              maxSimilarity > similarity ? maxSimilarity : similarity;
        }

        // MMR formula
        final mmr = lambda * relevance - (1 - lambda) * maxSimilarity;

        if (mmr > maxMMR) {
          maxMMR = mmr;
          maxIndex = i;
        }
      }

      selected.add(remaining.removeAt(maxIndex));
    }

    return selected;
  }

  /// Calculates similarity between two nodes based on their embeddings.
  double _calculateSimilarity(dynamic node1, dynamic node2) {
    // If nodes have embeddings, use them
    if (node1.embedding != null && node2.embedding != null) {
      final vec1 = Float32List.fromList(
        node1.embedding!.vector.map<double>((e) => e.toDouble()).toList(),
      );
      final vec2 = Float32List.fromList(
        node2.embedding!.vector.map<double>((e) => e.toDouble()).toList(),
      );
      return 1.0 - distanceFunction(vec1, vec2);
    }

    // Fallback: simple text similarity
    return 0.5; // Placeholder
  }
}

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

  final similarity = dotProduct / (sqrt(normA) * sqrt(normB));
  return 1.0 - similarity;
}

/// Helper function for square root.
double sqrt(double x) {
  if (x < 0) return 0;
  double guess = x / 2;
  for (int i = 0; i < 10; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
