import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'tokenizer.dart';

/// Configuration object for running text embedding models with TFLite.
class TFLiteTextEmbeddingConfig {
  const TFLiteTextEmbeddingConfig({
    required this.maxTokens,
    this.padId = 0,
    this.inputIdsIndex = 0,
    this.attentionMaskIndex,
    this.outputTensorIndex = 0,
    this.ensureAllocated = true,
    this.tokenizer = const WhitespaceHasherTokenizer(),
    this.extraInputsBuilder,
  }) : assert(maxTokens > 0, 'maxTokens must be positive');

  final int maxTokens;
  final int padId;
  final int inputIdsIndex;
  final int? attentionMaskIndex;
  final int outputTensorIndex;
  final bool ensureAllocated;
  final TextTokenizer tokenizer;
  final Map<int, Object> Function(String text, int maxTokens)?
  extraInputsBuilder;
}

/// Utility for running text embedding inference on a TFLite [Interpreter].
class TFLiteTextEmbeddingRunner {
  const TFLiteTextEmbeddingRunner(this.config);

  final TFLiteTextEmbeddingConfig config;

  Future<List<double>> infer(Interpreter interpreter, String text) async {
    if (config.ensureAllocated) {
      interpreter.allocateTensors();
    }

    final tokenized = config.tokenizer.tokenize(text, config.maxTokens);
    final inputIds = Int32List.fromList(
      tokenized.ids.take(config.maxTokens).toList(),
    );
    final attentionMask = Int32List.fromList(
      tokenized.attentionMask.take(config.maxTokens).toList(),
    );

    final inputCount = interpreter.getInputTensors().length;
    final inputs = List<Object>.filled(
      inputCount,
      const <int>[],
      growable: false,
    );
    final extraInputs =
        config.extraInputsBuilder?.call(text, config.maxTokens) ??
        const <int, Object>{};

    for (var i = 0; i < inputCount; i++) {
      if (i == config.inputIdsIndex) {
        inputs[i] = inputIds;
        continue;
      }
      if (config.attentionMaskIndex != null && i == config.attentionMaskIndex) {
        inputs[i] = attentionMask;
        continue;
      }
      final extra = extraInputs[i];
      if (extra != null) {
        inputs[i] = extra;
        continue;
      }
      throw ArgumentError('No input prepared for tensor index $i.');
    }

    final outputTensor = interpreter.getOutputTensor(config.outputTensorIndex);
    final outputSize = outputTensor.shape.reduce(
      (value, element) => value * element,
    );
    final outputBuffer = Float32List(outputSize);
    final outputs = <int, Object>{config.outputTensorIndex: outputBuffer};

    interpreter.runForMultipleInputs(inputs, outputs);

    if (outputTensor.shape.length >= 2 && outputTensor.shape.first == 1) {
      final dim = outputTensor.shape.last;
      return outputBuffer.sublist(0, math.min(dim, outputBuffer.length));
    }

    return outputBuffer.toList(growable: false);
  }
}
