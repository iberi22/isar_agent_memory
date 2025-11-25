import 'package:isar_agent_memory/isar_agent_memory.dart';

/// A re-ranking strategy that prioritizes more recent results.
///
/// This class re-ranks search results based on their creation or update timestamps.
class RecencyReRanker implements ReRankingStrategy {
  @override
  List<({MemoryNode node, double score})> reRank(
    List<({MemoryNode node, double score})> results, {
    String? query,
  }) {
    results.sort((a, b) {
      final dateA = a.node.updatedAt ?? a.node.createdAt;
      final dateB = b.node.updatedAt ?? b.node.createdAt;
      return dateB.compareTo(dateA);
    });
    return results;
  }
}
