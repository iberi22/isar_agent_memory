import 'dart:async';
import 'models/memory_node.dart';

/// Abstract interface for a re-ranking strategy.
///
/// This class defines the contract for different re-ranking algorithms
/// that can be applied to a list of search results.
abstract class ReRankingStrategy {
  /// Re-ranks a list of search results.
  ///
  /// [results] is the initial list of search results to be re-ranked.
  /// [query] is the original search query, required by some strategies like BM25.
  /// Returns a re-ranked list of search results.
  /// May return synchronously (existing strategies) or asynchronously (cross-encoder).
  FutureOr<List<({MemoryNode node, double score})>> reRank(
    List<({MemoryNode node, double score})> results, {
    String? query,
  });
}
