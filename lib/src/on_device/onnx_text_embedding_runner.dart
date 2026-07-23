import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import 'tokenizer.dart';

/// Runner that feeds token IDs and attention masks into an ONNX session
/// representing a text embedding model.
class OnnxTextEmbeddingRunner {
  const OnnxTextEmbeddingRunner({
    required this.maxTokens,
    required this.tokenizer,
    this.inputIdsName = 'input_ids',
    this.attentionMaskName = 'attention_mask',
    this.outputName = 'normalized_embedding',
  });

  final int maxTokens;
  final TextTokenizer tokenizer;
  final String inputIdsName;
  final String attentionMaskName;
  final String outputName;

  Future<List<double>> infer(OrtSession session, String text) async {
    final tokenized = tokenizer.tokenize(text, maxTokens);
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      <Int32List>[Int32List.fromList(tokenized.ids)],
      <int>[1, maxTokens],
    );
    final maskTensor = OrtValueTensor.createTensorWithDataList(
      <Int32List>[Int32List.fromList(tokenized.attentionMask)],
      <int>[1, maxTokens],
    );

    final runOptions = OrtRunOptions();
    try {
      final outputs = await session.runAsync(
        runOptions,
        <String, OrtValue>{
          inputIdsName: inputTensor,
          attentionMaskName: maskTensor,
        },
        <String>[outputName],
      );

      if (outputs == null || outputs.isEmpty || outputs.first == null) {
        throw StateError(
          'ONNX inference did not return outputs for $outputName',
        );
      }

      final tensor = outputs.first! as OrtValueTensor;
      final value = tensor.value;
      final flattened = _flattenNumeric(value);
      for (final output in outputs) {
        output?.release();
      }
      return flattened;
    } finally {
      inputTensor.release();
      maskTensor.release();
      runOptions.release();
    }
  }

  List<double> _flattenNumeric(Object value) {
    if (value is List) {
      return value.expand((element) => _flattenNumeric(element)).toList();
    }
    if (value is num) {
      return <double>[value.toDouble()];
    }
    throw StateError('Unexpected ONNX output type: ${value.runtimeType}');
  }
}
