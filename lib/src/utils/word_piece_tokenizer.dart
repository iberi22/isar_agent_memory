/// A simple WordPiece tokenizer for BERT-based models.
///
/// This implementation allows tokenizing text into subword indices expected by models
/// like all-MiniLM-L6-v2. It requires a vocabulary map.
class WordPieceTokenizer {
  final Map<String, int> vocab;
  final int unkTokenId;
  final int clsTokenId;
  final int sepTokenId;
  final int padTokenId;
  final bool doLowerCase;

  WordPieceTokenizer({
    required this.vocab,
    this.unkTokenId = 100,
    this.clsTokenId = 101,
    this.sepTokenId = 102,
    this.padTokenId = 0,
    this.doLowerCase = true,
  });

  /// Tokenizes the input text and returns a list of token IDs.
  /// Adds [CLS] at the beginning and [SEP] at the end.
  List<int> tokenize(String text) {
    final tokens = _tokenize(text);
    final ids = <int>[clsTokenId];
    for (final token in tokens) {
      ids.add(vocab[token] ?? unkTokenId);
    }
    ids.add(sepTokenId);
    return ids;
  }

  List<String> _tokenize(String text) {
    String cleanText = text;
    if (doLowerCase) {
      cleanText = cleanText.toLowerCase();
    }

    // Basic whitespace splitting
    final words = cleanText.split(RegExp(r'\s+'));
    final tokens = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;

      // Basic punctuation splitting could be added here if needed.
      // For now, we assume simple whitespace separation or pre-cleaned text.
      // A more robust implementation would split by punctuation as well.

      // WordPiece algorithm
      final chars = word.runes.toList();
      bool isBad = false;
      int start = 0;
      final subTokens = <String>[];

      while (start < chars.length) {
        int end = chars.length;
        String? curSubStr;

        while (start < end) {
          String subStr = String.fromCharCodes(chars.sublist(start, end));
          if (start > 0) {
            subStr = '##$subStr';
          }
          if (vocab.containsKey(subStr)) {
            curSubStr = subStr;
            break;
          }
          end--;
        }

        if (curSubStr == null) {
          isBad = true;
          break;
        }

        subTokens.add(curSubStr);
        start = end;
      }

      if (isBad) {
        tokens.add('[UNK]');
      } else {
        tokens.addAll(subTokens);
      }
    }
    return tokens;
  }
}
