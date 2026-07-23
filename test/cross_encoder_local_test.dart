import 'dart:io';
import 'package:test/test.dart';
import 'package:isar_agent_memory/src/rerankers/cross_encoder_reranker.dart';

void main() {
  group('LocalCrossEncoderAdapter', () {
    final modelPath = 'test_resources/model.onnx';
    final vocabPath = 'test_resources/vocab.txt';

    test('throws exception if model file missing', () async {
      final adapter = LocalCrossEncoderAdapter(
        modelPath: 'non_existent_model.onnx',
        vocabPath: 'non_existent_vocab.txt',
      );

      expect(
        () async => await adapter.initialize(),
        throwsA(isA<Exception>()),
      );
    });

    test('initializes and scores if files exist', () async {
      if (!File(modelPath).existsSync() || !File(vocabPath).existsSync()) {
        markTestSkipped(
            'Model files not found. Run tool/setup_on_device_test.dart to download them.');
      }

      final adapter = LocalCrossEncoderAdapter(
        modelPath: modelPath,
        vocabPath: vocabPath,
      );

      await adapter.initialize();

      // Test score
      final scoreVal = await adapter.score('Where is Paris?', 'Paris is the capital of France.');
      expect(scoreVal, isA<double>());
      expect(scoreVal, greaterThanOrEqualTo(0.0));
      expect(scoreVal, lessThanOrEqualTo(1.0));

      // Test scoreBatch
      final queries = 'Where is Paris?';
      final docs = [
        'Paris is the capital of France.',
        'The quick brown fox jumps over the lazy dog.',
        'Water freezes at 0 degrees Celsius.',
      ];

      final scores = await adapter.scoreBatch(queries, docs);
      expect(scores.length, equals(docs.length));
      for (final s in scores) {
        expect(s, isA<double>());
        expect(s, greaterThanOrEqualTo(0.0));
        expect(s, lessThanOrEqualTo(1.0));
      }

      adapter.release();
    });
  });
}
