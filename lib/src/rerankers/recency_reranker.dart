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
      final dateA = a.node.updatedAt ?? a.node.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.node.updatedAt ?? b.node.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return results;
  }
}
