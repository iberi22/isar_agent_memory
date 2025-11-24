import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:isar_agent_memory/src/embeddings_adapter.dart';
import 'package:isar_agent_memory/src/utils/word_piece_tokenizer.dart';

/// An embeddings adapter that runs entirely on-device using ONNX Runtime.
///
/// Designed to work with BERT-based models like `all-MiniLM-L6-v2`.
/// Requires the ONNX model file and the vocabulary file to be available locally.
class OnDeviceEmbeddingsAdapter implements EmbeddingsAdapter {
  final String modelPath;
  final String vocabPath;
  final int _dimension;

  late final OrtSession _session;
  late final WordPieceTokenizer _tokenizer;
  bool _initialized = false;

  // Cache the vocab to avoid re-reading file on every init if shared
  static Map<String, int>? _cachedVocab;

  OnDeviceEmbeddingsAdapter({
    required this.modelPath,
    required this.vocabPath,
    int dimension = 384, // Default for all-MiniLM-L6-v2
  }) : _dimension = dimension;

  @override
  String get providerName => 'on_device_onnx';

  @override
  int get dimension => _dimension;

  /// Initializes the ONNX session and loads the vocabulary.
  /// This must be called before [embed].
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Load Vocab
    if (_cachedVocab == null) {
      final vocabFile = File(vocabPath);
      if (!await vocabFile.exists()) {
        throw Exception('Vocabulary file not found at $vocabPath');
      }
      final lines = await vocabFile.readAsLines();
      _cachedVocab = {
        for (var i = 0; i < lines.length; i++) lines[i].trim(): i,
      };
    }

    _tokenizer = WordPieceTokenizer(vocab: _cachedVocab!);

    // 2. Init ONNX Session
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    // Set thread count or other options if needed
    // sessionOptions.setIntraOpNumThreads(1);

    // Note: Creating session from file path
    _session = OrtSession.fromFile(File(modelPath), sessionOptions);

    _initialized = true;
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!_initialized) {
      await initialize();
    }

    // 1. Tokenize
    final tokenIds = _tokenizer.tokenize(text);

    // 2. Prepare Inputs
    // ONNX Runtime for BERT usually expects: input_ids, attention_mask, token_type_ids
    // Shape: [batch_size, sequence_length] -> [1, length]

    final shape = [1, tokenIds.length];
    final inputIdsInt64 = Int64List.fromList(tokenIds);
    final attentionMaskInt64 =
        Int64List.fromList(List.filled(tokenIds.length, 1));
    final tokenTypeIdsInt64 =
        Int64List.fromList(List.filled(tokenIds.length, 0));

    // Create OrtValues
    final inputIdsOrt =
        OrtValueTensor.createTensorWithDataList(inputIdsInt64, shape);
    final attentionMaskOrt =
        OrtValueTensor.createTensorWithDataList(attentionMaskInt64, shape);
    final tokenTypeIdsOrt =
        OrtValueTensor.createTensorWithDataList(tokenTypeIdsInt64, shape);

    final inputs = {
      'input_ids': inputIdsOrt,
      'attention_mask': attentionMaskOrt,
      'token_type_ids': tokenTypeIdsOrt,
    };

    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;

    try {
      // 3. Run Inference
      outputs = _session.run(runOptions, inputs);

      // 4. Extract Embeddings
      // Usually the output is 'last_hidden_state' or similar.
      // For sentence embeddings, we often need Mean Pooling.
      // However, some exported models (like those from Optimum) might already output the pooled embedding.
      // Let's assume the standard raw BERT output: [batch, seq_len, hidden_size].
      // We will perform Mean Pooling here manually if the model doesn't do it.

      // Check outputs
      // Typical output names: 'last_hidden_state', 'pooler_output'
      // Or if exported specifically for sentence-transformers, it might be just 'embeddings'.

      // Let's try to find a valid output tensor.
      // For now, we assume 'last_hidden_state' exists or we take the first output.
      if (outputs.isEmpty || outputs.first == null) {
        throw Exception('No output returned from ONNX model.');
      }

      final outputValue = outputs.first!;
      // We expect a tensor
      final outputTensor = outputValue as OrtValueTensor;
      final outputData =
          outputTensor.value as List; // Should be flattened float list

      // If output is [1, 384] (already pooled), we are good.
      // If output is [1, seq_len, 384], we need to pool.

      // Simple heuristic: check total elements
      if (outputData.length == _dimension) {
        return outputData.map((e) => (e as num).toDouble()).toList();
      }

      // If larger, assume [1, seq_len, dim] and do Mean Pooling
      // Logic: Sum vectors for all tokens (respecting mask) and divide by count.
      // Since we passed a mask of all 1s and batch=1, we just average all vectors.

      final seqLen = tokenIds.length;
      if (outputData.length == seqLen * _dimension) {
        final pooled = List<double>.filled(_dimension, 0.0);

        for (var i = 0; i < seqLen; i++) {
          for (var j = 0; j < _dimension; j++) {
            // outputData is flattened: index = i * dim + j
            pooled[j] += (outputData[i * _dimension + j] as num).toDouble();
          }
        }

        for (var j = 0; j < _dimension; j++) {
          pooled[j] /= seqLen;
        }

        return pooled;
      }

      throw Exception(
          'Unexpected output shape from ONNX model. Expected dimension $_dimension or sequence length * $_dimension.');
    } finally {
      // Ensure native resources are released even if an exception occurs
      for (final entry in inputs.entries) {
        entry.value.release();
      }
      runOptions.release();
      if (outputs != null) {
        for (final v in outputs) {
          v?.release();
        }
      }
    }
  }

  /// Release native resources.
  void release() {
    if (_initialized) {
      _session.release();
      OrtEnv.instance.release();
      _initialized = false;
    }
  }
}
