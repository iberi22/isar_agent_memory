import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar_agent_memory/src/models/memory_node.dart';
import 'package:isar_agent_memory/src/rerankers/cross_encoder_reranker.dart';

void main() {
  group('RemoteCrossEncoderAdapter', () {
    test('Empty documents and empty query edge cases', () async {
      final client = MockClient((request) async {
        fail('Should not make HTTP requests for empty documents or empty query');
      });

      final adapter = RemoteCrossEncoderAdapter.cohere(
        apiKey: 'test-key',
        client: client,
      );

      // Empty documents
      final emptyDocs = await adapter.scoreBatch('query', []);
      expect(emptyDocs, isEmpty);

      // Empty query
      final emptyQuery = await adapter.scoreBatch('', ['doc1', 'doc2']);
      expect(emptyQuery, [0.0, 0.0]);
    });

    test('Cohere success response format (score and scoreBatch)', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer cohere-key');
        expect(request.headers['Content-Type'], 'application/json');

        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['model'], 'rerank-v3.5');
        expect(payload['query'], 'Is physical therapy good for back pain?');
        expect(payload['documents'], ['doc1', 'doc2']);

        return http.Response(
          jsonEncode({
            'results': [
              {'index': 0, 'relevance_score': 0.95},
              {'index': 1, 'relevance_score': 0.15},
            ],
          }),
          200,
        );
      });

      final adapter = RemoteCrossEncoderAdapter.cohere(
        apiKey: 'cohere-key',
        client: client,
      );

      final scores = await adapter.scoreBatch(
        'Is physical therapy good for back pain?',
        ['doc1', 'doc2'],
      );
      expect(scores, [0.95, 0.15]);

      final singleScore = await adapter.score(
        'Is physical therapy good for back pain?',
        'doc1',
      );
      expect(singleScore, 0.95);
    });

    test('HF success response format with single score and sigmoid', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'score': 0.0, // Sigmoid of 0.0 is 0.5
          }),
          200,
        );
      });

      final adapter = RemoteCrossEncoderAdapter.fromProvider(
        RerankerProvider.huggingface,
        apiKey: 'hf-key',
        client: client,
      );

      final scores = await adapter.scoreBatch('query', ['doc1']);
      expect(scores.length, 1);
      expect(scores.first, closeTo(0.5, 0.001));
    });

    test('HF success response format with fallback list and sigmoid', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'scores': [0.0, 2.1972], // sigmoid(0) = 0.5, sigmoid(2.1972) approx 0.9
          }),
          200,
        );
      });

      final adapter = RemoteCrossEncoderAdapter.fromProvider(
        RerankerProvider.huggingface,
        apiKey: 'hf-key',
        client: client,
      );

      final scores = await adapter.scoreBatch('query', ['doc1', 'doc2']);
      expect(scores.length, 2);
      expect(scores[0], closeTo(0.5, 0.01));
      expect(scores[1], closeTo(0.9, 0.01));
    });

    test('Error handling - 401 Unauthorized', () async {
      final client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final adapter = RemoteCrossEncoderAdapter.cohere(
        apiKey: 'invalid-key',
        client: client,
      );

      expect(
        () => adapter.scoreBatch('query', ['doc']),
        throwsA(
          isA<RerankerException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('HTTP 401')),
        ),
      );
    });

    test('Error handling - 429 Too Many Requests retry and fail', () {
      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('Rate limit exceeded', 429);
      });

      final adapter = RemoteCrossEncoderAdapter(
        apiUrl: 'https://api.cohere.com/v2/rerank',
        apiKey: 'test-key',
        model: 'rerank-v3.5',
        client: client,
        maxRetries: 1, // Will attempt initial + 1 retry = 2 calls total
      );

      fakeAsync((async) {
        bool done = false;
        adapter.scoreBatch('query', ['doc']).catchError((e) {
          expect(e, isA<RerankerException>());
          expect((e as RerankerException).statusCode, 429);
          done = true;
          return <double>[];
        });

        async.elapse(const Duration(seconds: 5));
        expect(done, isTrue);
        expect(requestCount, 2); // Initial request + 1 retry
      });
    });

    test('Error handling - 500 Server Error retry and fail', () {
      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('Internal Server Error', 500);
      });

      final adapter = RemoteCrossEncoderAdapter(
        apiUrl: 'https://api.cohere.com/v2/rerank',
        apiKey: 'test-key',
        model: 'rerank-v3.5',
        client: client,
        maxRetries: 1,
      );

      fakeAsync((async) {
        bool done = false;
        adapter.scoreBatch('query', ['doc']).catchError((e) {
          expect(e, isA<RerankerException>());
          expect((e as RerankerException).statusCode, 500);
          done = true;
          return <double>[];
        });

        async.elapse(const Duration(seconds: 5));
        expect(done, isTrue);
        expect(requestCount, 2);
      });
    });

    test('Error handling - Timeout retry and fail', () {
      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        // Delay for longer than the timeout
        await Future.delayed(const Duration(seconds: 5));
        return http.Response('OK', 200);
      });

      final adapter = RemoteCrossEncoderAdapter(
        apiUrl: 'https://api.cohere.com/v2/rerank',
        apiKey: 'test-key',
        model: 'rerank-v3.5',
        client: client,
        timeout: const Duration(seconds: 1),
        maxRetries: 1,
      );

      fakeAsync((async) {
        bool done = false;
        adapter.scoreBatch('query', ['doc']).catchError((e) {
          expect(e, isA<RerankerException>());
          expect((e as RerankerException).message, contains('timed out'));
          done = true;
          return <double>[];
        });

        // Each attempt times out after 1s, and then we delay for `attempt` seconds (1s).
        async.elapse(const Duration(seconds: 10));
        expect(done, isTrue);
        expect(requestCount, 2);
      });
    });

    test('CrossEncoderReranker Integration as ReRankingStrategy', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'results': [
              {'index': 0, 'relevance_score': 0.9},
              {'index': 1, 'relevance_score': 0.4},
            ],
          }),
          200,
        );
      });

      final adapter = RemoteCrossEncoderAdapter.cohere(
        apiKey: 'cohere-key',
        client: client,
      );

      final reranker = CrossEncoderReranker(encoder: adapter, minScore: 0.5);

      final results = [
        (node: MemoryNode(content: 'doc1'), score: 0.5),
        (node: MemoryNode(content: 'doc2'), score: 0.3),
      ];

      final reranked = await reranker.reRank(results, query: 'test query');
      // doc2 should be filtered out because score 0.4 is less than minScore 0.5
      expect(reranked.length, 1);
      expect(reranked[0].node.content, 'doc1');
      expect(reranked[0].score, 0.9);
    });

    test('Dispose releases underlying HTTP client', () {
      final client = MockClient((request) async => http.Response('OK', 200));
      final adapter = RemoteCrossEncoderAdapter.cohere(
        apiKey: 'cohere-key',
        client: client,
      );
      adapter.dispose();
      // Verifies dispose runs without throwing
    });
  });
}
