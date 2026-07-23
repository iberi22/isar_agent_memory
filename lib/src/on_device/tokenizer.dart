import 'dart:convert';
import 'dart:math' as math;

/// Result of tokenizing a string.
class TokenizedText {
  TokenizedText({required this.ids, required this.attentionMask});

  final List<int> ids;
  final List<int> attentionMask;
}

/// Base contract for text tokenizers used by on-device backends.
abstract class TextTokenizer {
  const TextTokenizer();

  TokenizedText tokenize(String text, int maxTokens);
}

/// Simple tokenizer that splits on whitespace and hashes tokens into a bounded vocabulary.
class WhitespaceHasherTokenizer extends TextTokenizer {
  const WhitespaceHasherTokenizer({
    this.padId = 0,
    this.unknownId = 1,
    this.vocabSize = 32000,
  });

  final int padId;
  final int unknownId;
  final int vocabSize;

  @override
  TokenizedText tokenize(String text, int maxTokens) {
    final words =
        text.trim().isEmpty ? <String>[] : text.trim().split(RegExp(r'\s+'));
    final ids = <int>[];
    for (final word in words) {
      if (ids.length == maxTokens) break;
      final hash = word.runes.fold<int>(
        0,
        (value, rune) => (value * 16777619) ^ rune,
      );
      final id = ((hash & 0x7fffffff) % vocabSize);
      ids.add(id == 0 ? unknownId : id);
    }

    final length = ids.length;
    if (length < maxTokens) {
      ids.addAll(List<int>.filled(maxTokens - length, padId));
    }

    final attention = List<int>.filled(maxTokens, 0);
    for (var i = 0; i < math.min(length, maxTokens); i++) {
      attention[i] = 1;
    }

    return TokenizedText(ids: ids, attentionMask: attention);
  }
}

/// Tokenizer that uses a provided vocabulary mapping tokens to IDs.
class VocabularyTokenizer extends TextTokenizer {
  VocabularyTokenizer({
    required Map<String, int> vocab,
    this.padId = 0,
    this.unknownId = 1,
    this.lowercase = true,
    this.prependToken,
    this.appendToken,
  }) : _vocab = Map<String, int>.unmodifiable(vocab);

  factory VocabularyTokenizer.fromJson(Map<String, Object?> json) {
    final vocab = Map<String, Object?>.from(json['vocab'] as Map);
    final mapped = <String, int>{};
    vocab.forEach((key, value) {
      mapped[key] = (value as num).toInt();
    });
    return VocabularyTokenizer(
      vocab: mapped,
      padId: (json['padding_id'] as num?)?.toInt() ?? 0,
      unknownId: (json['unknown_id'] as num?)?.toInt() ?? 1,
      lowercase: (json['lowercase'] as bool?) ?? true,
      prependToken: json['cls_token'] as String?,
      appendToken: json['sep_token'] as String?,
    );
  }

  factory VocabularyTokenizer.fromJsonString(String jsonString) {
    return VocabularyTokenizer.fromJson(
      Map<String, Object?>.from(jsonDecode(jsonString) as Map),
    );
  }

  final Map<String, int> _vocab;
  final int padId;
  final int unknownId;
  final bool lowercase;
  final String? prependToken;
  final String? appendToken;

  static final RegExp _tokenPattern = RegExp(r"[A-Za-z0-9_']+");

  int _lookup(String token) => _vocab[token] ?? unknownId;

  @override
  TokenizedText tokenize(String text, int maxTokens) {
    final tokens = <int>[];
    final attention = <int>[];

    void addToken(String token) {
      if (tokens.length >= maxTokens) {
        return;
      }
      tokens.add(_lookup(token));
      attention.add(1);
    }

    if (prependToken != null) {
      addToken(prependToken!);
    }

    final normalized = lowercase ? text.toLowerCase() : text;
    for (final match in _tokenPattern.allMatches(normalized)) {
      final token = match.group(0);
      if (token == null || token.isEmpty) {
        continue;
      }
      addToken(token);
      if (tokens.length >= maxTokens) {
        break;
      }
    }

    if (appendToken != null && tokens.length < maxTokens) {
      addToken(appendToken!);
    }

    if (tokens.length < maxTokens) {
      final padCount = maxTokens - tokens.length;
      tokens.addAll(List<int>.filled(padCount, padId));
      attention.addAll(List<int>.generate(padCount, (_) => 0));
    } else if (tokens.length > maxTokens) {
      tokens.removeRange(maxTokens, tokens.length);
      attention.removeRange(maxTokens, attention.length);
    }

    return TokenizedText(ids: tokens, attentionMask: attention);
  }
}
