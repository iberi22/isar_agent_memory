import 'dart:math';
import 'package:isar_agent_memory/isar_agent_memory.dart';

/// A re-ranking strategy based on the BM25 algorithm.
///
/// This class re-ranks search results based on term frequency.
class BM25ReRanker implements ReRankingStrategy {
  final double k1;
  final double b;

  BM25ReRanker({this.k1 = 1.5, this.b = 0.75});

  @override
  List<({MemoryNode node, double score})> reRank(
    List<({MemoryNode node, double score})> results, {
    String? query,
  }) {
    if (query == null || results.isEmpty) {
      return results;
    }

    final queryTerms = _tokenize(query);
    final documents = results.map((r) => _tokenize(r.node.content)).toList();
    final idf = _calculateIdf(queryTerms, documents);
    final avgdl = documents.map((d) => d.length).reduce((a, b) => a + b) /
        documents.length;

    results.sort((a, b) {
      final scoreA = _calculateBm25(
          queryTerms, _tokenize(a.node.content), documents, idf, avgdl);
      final scoreB = _calculateBm25(
          queryTerms, _tokenize(b.node.content), documents, idf, avgdl);
      return scoreB.compareTo(scoreA);
    });

    return results;
  }

  List<String> _tokenize(String text) {
    return text.toLowerCase().split(RegExp(r'\W+'));
  }

  Map<String, double> _calculateIdf(
      List<String> queryTerms, List<List<String>> documents) {
    final idf = <String, double>{};
    for (final term in queryTerms) {
      final docCount = documents.where((d) => d.contains(term)).length;
      idf[term] =
          log((documents.length - docCount + 0.5) / (docCount + 0.5) + 1);
    }
    return idf;
  }

  double _calculateBm25(List<String> queryTerms, List<String> doc,
      List<List<String>> documents, Map<String, double> idf, double avgdl) {
    double score = 0.0;
    for (final term in queryTerms) {
      if (!doc.contains(term)) {
        continue;
      }
      final tf = doc.where((t) => t == term).length;
      score += idf[term]! *
          (tf * (k1 + 1)) /
          (tf + k1 * (1 - b + b * (doc.length / avgdl)));
    }
    return score;
  }
}
