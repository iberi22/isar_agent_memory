import 'package:test/test.dart';
import 'package:isar_agent_memory/src/on_device/on_device_embedding_backend.dart';
import 'package:isar_agent_memory/src/on_device/hash_embedding_backend.dart';
import 'package:isar_agent_memory/src/on_device/resilient_embedding_backend.dart';
import 'package:isar_agent_memory/src/on_device/tokenizer.dart';

class StubEmbeddingBackend implements OnDeviceEmbeddingBackend {
  StubEmbeddingBackend({
    required this.runtime,
    required this.modelId,
    this.dimension = 128,
    this.failOnLoad = false,
    this.failOnInfer = false,
  });

  @override
  final String runtime;

  @override
  final String modelId;

  @override
  final int dimension;

  final bool failOnLoad;
  final bool failOnInfer;

  bool _isLoaded = false;
  int loadCalls = 0;
  int inferCalls = 0;
  int disposeCalls = 0;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() async {
    loadCalls++;
    if (failOnLoad) {
      throw Exception('Load failed on $runtime');
    }
    _isLoaded = true;
  }

  @override
  Future<List<double>> infer(String text) async {
    inferCalls++;
    if (failOnInfer) {
      throw Exception('Infer failed on $runtime');
    }
    return List<double>.generate(dimension, (i) => i.toDouble());
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    _isLoaded = false;
  }
}

void main() {
  group('HashEmbeddingBackend Unit Tests', () {
    test('default configuration and basic operations', () async {
      final backend = HashEmbeddingBackend();

      expect(backend.dimension, equals(256));
      expect(backend.runtime, equals('hash'));
      expect(backend.modelId, equals('hash-embeddings-v1'));
      expect(backend.isLoaded, isTrue);

      await backend.load(); // should be a no-op
      await backend.dispose(); // should be a no-op
    });

    test('custom dimension configuration', () async {
      final backend = HashEmbeddingBackend(dimension: 128);
      expect(backend.dimension, equals(128));

      final embedding = await backend.infer('hello');
      expect(embedding.length, equals(128));
    });

    test('deterministic vectors', () async {
      final backend = HashEmbeddingBackend(dimension: 256);
      final text = 'Lorem ipsum dolor sit amet';

      final embedding1 = await backend.infer(text);
      final embedding2 = await backend.infer(text);
      final embedding3 = await backend.infer('Different text');

      expect(embedding1, equals(embedding2));
      expect(embedding1, isNot(equals(embedding3)));
    });

    test('empty string behavior', () async {
      final backend = HashEmbeddingBackend(dimension: 256);
      final embedding = await backend.infer('');

      expect(embedding.length, equals(256));
      expect(embedding.every((val) => val == 0.0), isTrue);
    });

    test('throws assertion error for invalid dimension', () {
      expect(() => HashEmbeddingBackend(dimension: 0),
          throwsA(isA<AssertionError>()));
      expect(() => HashEmbeddingBackend(dimension: -5),
          throwsA(isA<AssertionError>()));
    });
  });

  group('ResilientEmbeddingBackend Unit Tests', () {
    test('primary success behavior', () async {
      final primary = StubEmbeddingBackend(
          runtime: 'primary-run', modelId: 'primary-mod', dimension: 100);
      final fallback = StubEmbeddingBackend(
          runtime: 'fallback-run', modelId: 'fallback-mod', dimension: 200);

      final resilient = ResilientEmbeddingBackend(
        primary: primary,
        fallback: fallback,
      );

      expect(resilient.runtime, equals('primary-run'));
      expect(resilient.modelId, equals('primary-mod'));
      expect(resilient.dimension, equals(100));
      expect(resilient.isLoaded, isFalse);

      await resilient.load();

      expect(resilient.isLoaded, isTrue);
      expect(primary.isLoaded, isTrue);
      expect(fallback.isLoaded, isFalse);
      expect(primary.loadCalls, equals(1));
      expect(fallback.loadCalls, equals(0));

      final embedding = await resilient.infer('test');
      expect(embedding.length, equals(100));
      expect(primary.inferCalls, equals(1));
      expect(fallback.inferCalls, equals(0));

      await resilient.dispose();
      expect(primary.disposeCalls, equals(1));
      expect(fallback.disposeCalls, equals(1));
    });

    test('primary load fails, falls back successfully', () async {
      final primary = StubEmbeddingBackend(
          runtime: 'primary-run',
          modelId: 'primary-mod',
          dimension: 100,
          failOnLoad: true);
      final fallback = StubEmbeddingBackend(
          runtime: 'fallback-run', modelId: 'fallback-mod', dimension: 200);

      var callbackTriggered = false;
      final resilient = ResilientEmbeddingBackend(
        primary: primary,
        fallback: fallback,
        onFallback: (err, stack) {
          callbackTriggered = true;
          expect(err.toString(), contains('Load failed on primary-run'));
        },
      );

      await resilient.load();

      expect(callbackTriggered, isTrue);
      expect(resilient.isLoaded, isTrue);
      expect(primary.isLoaded, isFalse);
      expect(fallback.isLoaded, isTrue);
      expect(primary.loadCalls, equals(1));
      expect(fallback.loadCalls, equals(1));

      expect(resilient.runtime, equals('fallback-run'));
      expect(resilient.modelId, equals('fallback-mod'));
      expect(resilient.dimension, equals(200));

      final embedding = await resilient.infer('test');
      expect(embedding.length, equals(200));
      expect(primary.inferCalls, equals(0));
      expect(fallback.inferCalls, equals(1));
    });

    test('primary infer fails, falls back successfully', () async {
      final primary = StubEmbeddingBackend(
          runtime: 'primary-run',
          modelId: 'primary-mod',
          dimension: 100,
          failOnInfer: true);
      final fallback = StubEmbeddingBackend(
          runtime: 'fallback-run', modelId: 'fallback-mod', dimension: 200);

      var callbackTriggered = false;
      final resilient = ResilientEmbeddingBackend(
        primary: primary,
        fallback: fallback,
        onFallback: (err, stack) {
          callbackTriggered = true;
          expect(err.toString(), contains('Infer failed on primary-run'));
        },
      );

      // Primary load should succeed initially
      await resilient.load();
      expect(resilient.isLoaded, isTrue);
      expect(primary.isLoaded, isTrue);
      expect(fallback.isLoaded, isFalse);

      // Inference on primary should fail and trigger fallback load and fallback inference
      final embedding = await resilient.infer('test');
      expect(callbackTriggered, isTrue);
      expect(embedding.length, equals(200));
      expect(primary.inferCalls, equals(1));
      expect(fallback.loadCalls, equals(1));
      expect(fallback.inferCalls, equals(1));

      expect(resilient.runtime, equals('fallback-run'));
      expect(resilient.modelId, equals('fallback-mod'));
      expect(resilient.dimension, equals(200));
    });
  });

  group('WhitespaceHasherTokenizer Unit Tests', () {
    test('basic whitespace tokenization and hashing', () {
      const tokenizer = WhitespaceHasherTokenizer(vocabSize: 1000);
      final text = 'hello world';
      final maxTokens = 5;

      final tokenized = tokenizer.tokenize(text, maxTokens);
      expect(tokenized.ids.length, equals(5));
      expect(tokenized.attentionMask.length, equals(5));

      // First two are words, next three are padding (default padId = 0)
      expect(tokenized.ids[0], isNot(equals(0)));
      expect(tokenized.ids[1], isNot(equals(0)));
      expect(tokenized.ids[2], equals(0));
      expect(tokenized.ids[3], equals(0));
      expect(tokenized.ids[4], equals(0));

      expect(tokenized.attentionMask, equals([1, 1, 0, 0, 0]));
    });

    test('truncation when text exceeds max tokens', () {
      const tokenizer = WhitespaceHasherTokenizer(vocabSize: 1000);
      final text = 'one two three four five';
      final tokenized = tokenizer.tokenize(text, 3);

      expect(tokenized.ids.length, equals(3));
      expect(tokenized.attentionMask, equals([1, 1, 1]));
    });

    test('empty or whitespace-only inputs', () {
      const tokenizer = WhitespaceHasherTokenizer(vocabSize: 1000, padId: 99);

      final tokenizedEmpty = tokenizer.tokenize('', 4);
      expect(tokenizedEmpty.ids, equals([99, 99, 99, 99]));
      expect(tokenizedEmpty.attentionMask, equals([0, 0, 0, 0]));

      final tokenizedSpaces = tokenizer.tokenize('    ', 3);
      expect(tokenizedSpaces.ids, equals([99, 99, 99]));
      expect(tokenizedSpaces.attentionMask, equals([0, 0, 0]));
    });

    test('hashing is deterministic', () {
      const tokenizer = WhitespaceHasherTokenizer();
      final text = 'same-token';

      final tok1 = tokenizer.tokenize(text, 2);
      final tok2 = tokenizer.tokenize(text, 2);

      expect(tok1.ids[0], equals(tok2.ids[0]));
    });
  });

  group('VocabularyTokenizer Unit Tests', () {
    final vocab = {
      '[PAD]': 0,
      '[UNK]': 1,
      '[CLS]': 2,
      '[SEP]': 3,
      'hello': 10,
      'world': 11,
      'test': 12,
    };

    test('manual vocabulary initialization and lookup', () {
      final tokenizer = VocabularyTokenizer(
        vocab: vocab,
        padId: 0,
        unknownId: 1,
        lowercase: true,
      );

      final tokenized = tokenizer.tokenize('hello world unknown', 5);
      expect(tokenized.ids, equals([10, 11, 1, 0, 0]));
      expect(tokenized.attentionMask, equals([1, 1, 1, 0, 0]));
    });

    test('prepending and appending special tokens', () {
      final tokenizer = VocabularyTokenizer(
        vocab: vocab,
        padId: 0,
        unknownId: 1,
        lowercase: true,
        prependToken: '[CLS]',
        appendToken: '[SEP]',
      );

      final tokenized = tokenizer.tokenize('hello world', 5);
      expect(tokenized.ids, equals([2, 10, 11, 3, 0]));
      expect(tokenized.attentionMask, equals([1, 1, 1, 1, 0]));
    });

    test('truncation with prepended/appended tokens', () {
      final tokenizer = VocabularyTokenizer(
        vocab: vocab,
        padId: 0,
        unknownId: 1,
        lowercase: true,
        prependToken: '[CLS]',
        appendToken: '[SEP]',
      );

      // maxTokens is 3. Prepend [CLS] (idx 0), text "hello" (idx 1), text "world" (idx 2).
      // Max tokens is hit, so append [SEP] is not added.
      final tokenized = tokenizer.tokenize('hello world test', 3);
      expect(tokenized.ids, equals([2, 10, 11]));
      expect(tokenized.attentionMask, equals([1, 1, 1]));
    });

    test('case sensitivity options', () {
      final lowercaseTokenizer = VocabularyTokenizer(
        vocab: vocab,
        lowercase: true,
      );
      final uppercaseOnlyVocab = {
        'HELLO': 10,
        'WORLD': 11,
      };
      final caseSensitiveTokenizer = VocabularyTokenizer(
        vocab: uppercaseOnlyVocab,
        lowercase: false,
        unknownId: 99,
      );

      final res1 = lowercaseTokenizer.tokenize('HELLO', 2);
      expect(res1.ids[0], equals(10)); // HELLO -> hello -> 10

      final res2 = caseSensitiveTokenizer.tokenize('hello', 2);
      expect(res2.ids[0], equals(99)); // hello doesn't match HELLO

      final res3 = caseSensitiveTokenizer.tokenize('HELLO', 2);
      expect(res3.ids[0], equals(10)); // HELLO matches HELLO
    });

    test('fromJson and fromJsonString factories', () {
      final jsonMap = {
        'vocab': {
          '[PAD]': 0,
          '[UNK]': 1,
          '[CLS]': 2,
          'token': 5,
        },
        'padding_id': 0,
        'unknown_id': 1,
        'lowercase': true,
        'cls_token': '[CLS]',
      };

      final tokenizerFromMap = VocabularyTokenizer.fromJson(jsonMap);
      expect(tokenizerFromMap.padId, equals(0));
      expect(tokenizerFromMap.unknownId, equals(1));
      expect(tokenizerFromMap.prependToken, equals('[CLS]'));

      final tokenized1 = tokenizerFromMap.tokenize('token', 3);
      expect(tokenized1.ids, equals([2, 5, 0]));

      final jsonString =
          '{"vocab": {"[PAD]": 0, "token": 42}, "padding_id": 0, "unknown_id": 1}';
      final tokenizerFromString =
          VocabularyTokenizer.fromJsonString(jsonString);
      final tokenized2 = tokenizerFromString.tokenize('token', 2);
      expect(tokenized2.ids, equals([42, 0]));
    });
  });
}
