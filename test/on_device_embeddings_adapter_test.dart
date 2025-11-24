import 'dart:io';
import 'package:test/test.dart';
import 'package:isar_agent_memory/src/on_device_embeddings_adapter.dart';

void main() {
  group('OnDeviceEmbeddingsAdapter', () {
    final modelPath = 'test_resources/model.onnx';
    final vocabPath = 'test_resources/vocab.txt';

    test('throws exception if model file missing', () async {
      final adapter = OnDeviceEmbeddingsAdapter(
        modelPath: 'non_existent_model.onnx',
        vocabPath: 'non_existent_vocab.txt',
      );

      expect(
        () async => await adapter.initialize(),
        throwsA(isA<Exception>()),
      );
    });

    test('initializes and embeds if files exist', () async {
      if (!File(modelPath).existsSync() || !File(vocabPath).existsSync()) {
        markTestSkipped('Model files not found. Run tool/setup_on_device_test.dart to download them.');
      }

      final adapter = OnDeviceEmbeddingsAdapter(
        modelPath: modelPath,
        vocabPath: vocabPath,
      );

      await adapter.initialize();
      expect(adapter.dimension, equals(384));

      final embedding = await adapter.embed('Hello world');
      expect(embedding.length, equals(384));

      adapter.release();
    });
  });
}
