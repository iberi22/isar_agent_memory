import 'package:flutter_test/flutter_test.dart';
import 'package:isar_agent_memory/isar_agent_memory.dart';

void main() {
  group('ReRankingStrategy', () {
    test('RecencyReRanker test', () {
      final reranker = RecencyReRanker();
      final now = DateTime.now();
      final results = [
        (
          node: MemoryNode(
              content: 'older',
              createdAt: now.subtract(const Duration(days: 1))),
          score: 0.8
        ),
        (node: MemoryNode(content: 'newer', createdAt: now), score: 0.7),
      ];

      final reranked = reranker.reRank(results);
      expect(reranked.first.node.content, 'newer');
    });

    test('MMRReRanker test', () {
      final reranker = MMRReRanker();
      final results = [
        (
          node: MemoryNode(
              content: 'very relevant, very similar',
              embedding: MemoryEmbedding(vector: [1.0, 0.0])),
          score: 0.9
        ),
        (
          node: MemoryNode(
              content: 'very relevant, less similar',
              embedding: MemoryEmbedding(vector: [0.0, 1.0])),
          score: 0.8
        ),
        (
          node: MemoryNode(
              content: 'less relevant, very similar',
              embedding: MemoryEmbedding(vector: [0.9, 0.1])),
          score: 0.5
        ),
      ];

      final reranked = reranker.reRank(results);
      expect(reranked[0].node.content, 'very relevant, very similar');
      expect(reranked[1].node.content, 'very relevant, less similar');
    });

    test('DiversityReRanker test', () {
      final reranker = DiversityReRanker();
      final results = [
        (
          node: MemoryNode(
              content: 'item 1',
              embedding: MemoryEmbedding(vector: [1.0, 0.0])),
          score: 0.9
        ),
        (
          node: MemoryNode(
              content: 'item 2 (similar to 1)',
              embedding: MemoryEmbedding(vector: [0.9, 0.1])),
          score: 0.8
        ),
        (
          node: MemoryNode(
              content: 'item 3 (different)',
              embedding: MemoryEmbedding(vector: [0.0, 1.0])),
          score: 0.7
        ),
      ];

      final reranked = reranker.reRank(results);
      expect(reranked[0].node.content, 'item 1');
      expect(reranked[1].node.content, 'item 3 (different)');
    });

    test('BM25ReRanker test', () {
      final reranker = BM25ReRanker();
      final results = [
        (node: MemoryNode(content: 'the quick brown fox'), score: 0.9),
        (node: MemoryNode(content: 'a lazy dog'), score: 0.8),
        (
          node: MemoryNode(
              content: 'the quick brown fox jumps over the lazy dog'),
          score: 0.7
        ),
      ];

      final reranked = reranker.reRank(results, query: 'quick fox');
      expect(reranked[0].node.content, 'the quick brown fox');
      expect(reranked[1].node.content,
          'the quick brown fox jumps over the lazy dog');
    });
  });
}
