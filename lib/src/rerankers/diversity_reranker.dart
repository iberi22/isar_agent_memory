import 'dart:math';
import 'package:isar_agent_memory/isar_agent_memory.dart';

/// A re-ranking strategy that maximizes the diversity of the results.
///
/// This class re-ranks search results to avoid showing similar results.
class DiversityReRanker implements ReRankingStrategy {
  @override
  List<({MemoryNode node, double score})> reRank(
    List<({MemoryNode node, double score})> results, {
    String? query,
  }) {
    if (results.isEmpty) {
      return [];
    }

    final reranked = <({MemoryNode node, double score})>[];
    final remaining = List.of(results);

    reranked.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      var bestCandidate = remaining.first;
      var bestScore = double.infinity;

      for (final candidate in remaining) {
        final similarity = reranked
            .map((r) => _cosineSimilarity(
                r.node.embedding?.vector, candidate.node.embedding?.vector))
            .reduce(max);

        if (similarity < bestScore) {
          bestScore = similarity;
          bestCandidate = candidate;
        }
      }

      reranked.add(bestCandidate);
      remaining.remove(bestCandidate);
    }

    return reranked;
  }

  double _cosineSimilarity(List<double>? a, List<double>? b) {
    if (a == null || b == null || a.length != b.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
