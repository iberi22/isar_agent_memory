import 'package:test/test.dart';
import 'package:isar_agent_memory/src/utils/word_piece_tokenizer.dart';

void main() {
  group('WordPieceTokenizer', () {
    late WordPieceTokenizer tokenizer;
    late Map<String, int> vocab;

    setUp(() {
      vocab = {
        '[PAD]': 0,
        '[UNK]': 1,
        '[CLS]': 2,
        '[SEP]': 3,
        '[MASK]': 4,
        'the': 10,
        'quick': 11,
        'brown': 12,
        'fox': 13,
        'jumps': 14,
        'over': 15,
        'lazy': 16,
        'dog': 17,
        '##s': 18,
        '##ing': 19,
        'un': 20,
        '##do': 21,
        'hello': 22,
        'world': 23,
      };

      tokenizer = WordPieceTokenizer(
        vocab: vocab,
        unkTokenId: 1,
        clsTokenId: 2,
        sepTokenId: 3,
        padTokenId: 0,
      );
    });

    test('tokenizes simple sentence correctly', () {
      final text = 'the quick brown fox';
      final tokens = tokenizer.tokenize(text);

      // Expected: [CLS], the, quick, brown, fox, [SEP]
      expect(tokens, equals([2, 10, 11, 12, 13, 3]));
    });

    test('handles unknown words with [UNK]', () {
      final text = 'the quick zebra';
      final tokens = tokenizer.tokenize(text);

      // 'zebra' is not in vocab -> [UNK]
      // Expected: [CLS], the, quick, [UNK], [SEP]
      expect(tokens, equals([2, 10, 11, 1, 3]));
    });

    test('handles subwords (if vocab supported)', () {
      // vocab has 'jump' (no), 'jumps' (yes)
      // vocab has '##s'
      // Let's test 'jumps' which is a full word in vocab
      final text = 'jumps';
      final tokens = tokenizer.tokenize(text);
      expect(tokens, equals([2, 14, 3]));
    });

    test('handles subword splitting', () {
      // vocab: 'un', '##do'
      final text = 'undo';
      final tokens = tokenizer.tokenize(text);

      // 'undo' -> 'un' + '##do'
      // Expected: [CLS], un, ##do, [SEP]
      expect(tokens, equals([2, 20, 21, 3]));
    });

    test('lowercases input by default', () {
      final text = 'The Quick Brown Fox';
      final tokens = tokenizer.tokenize(text);

      // Should match lowercase tokens
      expect(tokens, equals([2, 10, 11, 12, 13, 3]));
    });

    test('handles empty string', () {
      final text = '';
      final tokens = tokenizer.tokenize(text);

      // Expected: [CLS], [SEP]
      expect(tokens, equals([2, 3]));
    });
  });
}
