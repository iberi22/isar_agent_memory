import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:isar_agent_memory/src/embeddings_adapter.dart';
import 'package:isar_agent_memory/src/utils/word_piece_tokenizer.dart';

/// A safe on-device embeddings adapter that correctly handles nested lists
/// returned by the ONNX runtime library in various platforms/environments.
class SafeOnDeviceEmbeddingsAdapter implements EmbeddingsAdapter {
  final String modelPath;
  final String vocabPath;
  final int _dimension;

  late final OrtSession _session;
  late final WordPieceTokenizer _tokenizer;
  bool _initialized = false;

  static Map<String, int>? _cachedVocab;

  SafeOnDeviceEmbeddingsAdapter({
    required this.modelPath,
    required this.vocabPath,
    int dimension = 384,
  }) : _dimension = dimension;

  @override
  String get providerName => 'safe_on_device_onnx';

  @override
  int get dimension => _dimension;

  Future<void> initialize() async {
    if (_initialized) return;

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

    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromFile(File(modelPath), sessionOptions);

    _initialized = true;
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!_initialized) {
      await initialize();
    }

    final tokenIds = _tokenizer.tokenize(text);
    final shape = [1, tokenIds.length];
    final inputIdsInt64 = Int64List.fromList(tokenIds);
    final attentionMaskInt64 =
        Int64List.fromList(List.filled(tokenIds.length, 1));
    final tokenTypeIdsInt64 =
        Int64List.fromList(List.filled(tokenIds.length, 0));

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
      outputs = _session.run(runOptions, inputs);

      if (outputs.isEmpty || outputs.first == null) {
        throw Exception('No output returned from ONNX model.');
      }

      final outputValue = outputs.first!;
      final outputTensor = outputValue as OrtValueTensor;
      final rawValue = outputTensor.value;

      return parseOutput(rawValue, _dimension);
    } finally {
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

  List<double> parseOutput(dynamic value, int expectedDim) {
    if (value is List<double>) {
      return value;
    }
    if (value is List<num>) {
      return value.map((e) => e.toDouble()).toList();
    }
    if (value is List) {
      if (value.isEmpty) {
        throw Exception('Empty output from ONNX model');
      }
      final first = value.first;
      if (first is List) {
        if (first.first is List) {
          // 3D structure: [batch, seq_len, dim]
          final batch = value;
          final firstBatch = batch[0] as List;
          final seqLen = firstBatch.length;
          if (seqLen == 0) throw Exception('Sequence length is zero');
          final dim = (firstBatch[0] as List).length;
          final pooled = List<double>.filled(dim, 0.0);
          for (var i = 0; i < seqLen; i++) {
            final tokenVec = firstBatch[i] as List;
            for (var j = 0; j < dim; j++) {
              pooled[j] += (tokenVec[j] as num).toDouble();
            }
          }
          for (var j = 0; j < dim; j++) {
            pooled[j] /= seqLen;
          }
          return pooled;
        } else {
          // 2D structure: [batch, dim]
          final list2d = value;
          final firstBatch = list2d[0] as List;
          return firstBatch.map((e) => (e as num).toDouble()).toList();
        }
      } else {
        // 1D structure
        return value.map((e) => (e as num).toDouble()).toList();
      }
    }
    throw Exception('Unknown output structure: ${value.runtimeType}');
  }

  void release() {
    if (_initialized) {
      _session.release();
      OrtEnv.instance.release();
      _initialized = false;
    }
  }
}

/// Helper function to calculate cosine similarity between two vectors.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError(
        'Vectors must be of the same length (${a.length} vs ${b.length})');
  }
  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0.0 || normB == 0.0) {
    return 0.0;
  }
  return dotProduct / (sqrt(normA) * sqrt(normB));
}

Future<void> main() async {
  print('Starting Embedding Quality & Latency Benchmark Suite...');

  // 1. Setup paths
  final modelPath = 'test_resources/model.onnx';
  final vocabPath = 'test_resources/vocab.txt';
  final queriesPath = 'tool/test_queries.json';

  if (!File(modelPath).existsSync() || !File(vocabPath).existsSync()) {
    print(
        'Error: Model files not found. Run "dart run tool/setup_on_device_test.dart" first.');
    exit(1);
  }

  if (!File(queriesPath).existsSync()) {
    print('Error: test_queries.json not found at $queriesPath.');
    exit(1);
  }

  final adapter = SafeOnDeviceEmbeddingsAdapter(
    modelPath: modelPath,
    vocabPath: vocabPath,
  );

  print('Initializing adapter...');
  await adapter.initialize();

  // Warmup
  print('Warming up embedding model...');
  for (var i = 0; i < 5; i++) {
    await adapter.embed('Warmup embedding request number $i');
  }

  // 2. Load Evaluation Dataset
  final datasetJson = json.decode(await File(queriesPath).readAsString());
  final List<dynamic> corpusList = datasetJson['corpus'];
  final List<dynamic> queriesList = datasetJson['queries'];

  print(
      'Loaded ${corpusList.length} documents and ${queriesList.length} test queries.');

  // 3. Pre-compute corpus embeddings while measuring performance/latency
  print('Computing corpus embeddings and profiling latency...');
  final corpusEmbeddings = <String, List<double>>{};
  final latencies = <int>[];
  final stopwatch = Stopwatch();

  // We run multiple iterations to get accurate latencies
  final iterations = 10;
  for (var iter = 0; iter < iterations; iter++) {
    for (final doc in corpusList) {
      final text = doc['text'] as String;
      final id = doc['id'] as String;

      stopwatch.reset();
      stopwatch.start();
      final embedding = await adapter.embed(text);
      stopwatch.stop();

      latencies.add(stopwatch.elapsedMicroseconds);
      if (iter == 0) {
        corpusEmbeddings[id] = embedding;
      }
    }
  }

  // 4. Run Retrieval Quality Evaluations
  print('Evaluating retrieval quality (Recall@k and Precision@k)...');

  final List<Map<String, dynamic>> queryEvaluations = [];
  final Map<String, List<double>> catP1 = {};
  final Map<String, List<double>> catR1 = {};
  final Map<String, List<double>> catP3 = {};
  final Map<String, List<double>> catR3 = {};
  final Map<String, List<double>> catP5 = {};
  final Map<String, List<double>> catR5 = {};

  for (final qObj in queriesList) {
    final queryId = qObj['id'] as String;
    final queryText = qObj['query'] as String;
    final category = qObj['category'] as String;
    final List<dynamic> expectedDocIds = qObj['expected_doc_ids'];

    // Embed query
    final queryEmbedding = await adapter.embed(queryText);

    // Score all documents
    final docScores = <Map<String, dynamic>>[];
    for (final doc in corpusList) {
      final docId = doc['id'] as String;
      final docEmbedding = corpusEmbeddings[docId]!;
      final score = cosineSimilarity(queryEmbedding, docEmbedding);
      docScores.add({
        'id': docId,
        'score': score,
      });
    }

    // Sort descending by score
    docScores
        .sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Calculate recall and precision for k = 1, 3, 5
    double calculatePrecision(int k) {
      final retrievedAtK =
          docScores.take(k).map((d) => d['id'] as String).toSet();
      final relevantRetrieved =
          retrievedAtK.intersection(expectedDocIds.toSet()).length;
      return relevantRetrieved / k;
    }

    double calculateRecall(int k) {
      final retrievedAtK =
          docScores.take(k).map((d) => d['id'] as String).toSet();
      final relevantRetrieved =
          retrievedAtK.intersection(expectedDocIds.toSet()).length;
      return relevantRetrieved / expectedDocIds.length;
    }

    final p1 = calculatePrecision(1);
    final r1 = calculateRecall(1);
    final p3 = calculatePrecision(3);
    final r3 = calculateRecall(3);
    final p5 = calculatePrecision(5);
    final r5 = calculateRecall(5);

    // Record category-wise scores
    catP1.putIfAbsent(category, () => []).add(p1);
    catR1.putIfAbsent(category, () => []).add(r1);
    catP3.putIfAbsent(category, () => []).add(p3);
    catR3.putIfAbsent(category, () => []).add(r3);
    catP5.putIfAbsent(category, () => []).add(p5);
    catR5.putIfAbsent(category, () => []).add(r5);

    queryEvaluations.add({
      'query_id': queryId,
      'query_text': queryText,
      'category': category,
      'expected_doc_ids': expectedDocIds,
      'retrieved_docs': docScores
          .take(5)
          .map((d) => {
                'id': d['id'],
                'score': d['score'],
              })
          .toList(),
      'metrics': {
        'precision_at_1': p1,
        'recall_at_1': r1,
        'precision_at_3': p3,
        'recall_at_3': r3,
        'precision_at_5': p5,
        'recall_at_5': r5,
      }
    });
  }

  // Release adapter resources
  adapter.release();

  // Calculate Overall Averages
  double avgList(List<double> list) =>
      list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;

  final allP1 = queryEvaluations
      .map((q) => q['metrics']['precision_at_1'] as double)
      .toList();
  final allR1 = queryEvaluations
      .map((q) => q['metrics']['recall_at_1'] as double)
      .toList();
  final allP3 = queryEvaluations
      .map((q) => q['metrics']['precision_at_3'] as double)
      .toList();
  final allR3 = queryEvaluations
      .map((q) => q['metrics']['recall_at_3'] as double)
      .toList();
  final allP5 = queryEvaluations
      .map((q) => q['metrics']['precision_at_5'] as double)
      .toList();
  final allR5 = queryEvaluations
      .map((q) => q['metrics']['recall_at_5'] as double)
      .toList();

  final overallP1 = avgList(allP1);
  final overallR1 = avgList(allR1);
  final overallP3 = avgList(allP3);
  final overallR3 = avgList(allR3);
  final overallP5 = avgList(allP5);
  final overallR5 = avgList(allR5);

  // Generate Category Summary
  final Map<String, dynamic> byCategoryResults = {};
  for (final category in catP1.keys) {
    byCategoryResults[category] = {
      'precision_at_1': avgList(catP1[category]!),
      'recall_at_1': avgList(catR1[category]!),
      'precision_at_3': avgList(catP3[category]!),
      'recall_at_3': avgList(catR3[category]!),
      'precision_at_5': avgList(catP5[category]!),
      'recall_at_5': avgList(catR5[category]!),
    };
  }

  // 5. Analyze Latencies
  latencies.sort();
  final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
  final p50 = latencies[(latencies.length * 0.50).floor()];
  final p90 = latencies[(latencies.length * 0.90).floor()];
  final p95 = latencies[(latencies.length * 0.95).floor()];
  final p99 = latencies[(latencies.length * 0.99).floor()];
  final minLatency = latencies.first;
  final maxLatency = latencies.last;

  double toMs(num micro) => micro / 1000.0;

  // 6. Build Final JSON Output
  final benchmarkOutput = {
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'metadata': {
      'os': Platform.operatingSystem,
      'cores': Platform.numberOfProcessors,
      'model': 'all-MiniLM-L6-v2 (INT8)',
      'provider': 'ONNX Runtime',
      'embedding_dimension': 384,
    },
    'performance': {
      'total_inferences': latencies.length,
      'latency_avg_ms': toMs(avgLatency),
      'latency_min_ms': toMs(minLatency),
      'latency_p50_ms': toMs(p50),
      'latency_p90_ms': toMs(p90),
      'latency_p95_ms': toMs(p95),
      'latency_p99_ms': toMs(p99),
      'latency_max_ms': toMs(maxLatency),
      'inferences_per_second': 1000000.0 / avgLatency,
    },
    'retrieval_quality': {
      'aggregate': {
        'precision_at_1': overallP1,
        'recall_at_1': overallR1,
        'precision_at_3': overallP3,
        'recall_at_3': overallR3,
        'precision_at_5': overallP5,
        'recall_at_5': overallR5,
      },
      'by_category': byCategoryResults,
      'queries': queryEvaluations,
    },
  };

  // Write output JSON
  final outputFile = File('tool/benchmark_output.json');
  await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(benchmarkOutput));
  print('Saved benchmark output to tool/benchmark_output.json');

  // Print results summary to Console
  print('\n===============================================================');
  print('                  BENCHMARK EVALUATION SUMMARY                 ');
  print('===============================================================');
  print(
      'Device: ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)');
  print('Model:  all-MiniLM-L6-v2 (INT8)');
  print('\n--- PERFORMANCE LATENCY ---');
  print('Average Latency:  ${toMs(avgLatency).toStringAsFixed(2)} ms');
  print('p50 Latency:      ${toMs(p50).toStringAsFixed(2)} ms');
  print('p95 Latency:      ${toMs(p95).toStringAsFixed(2)} ms');
  print(
      'Throughput (IPS): ${(1000000.0 / avgLatency).toStringAsFixed(1)} inf/sec');
  print('\n--- RETRIEVAL QUALITY (OVERALL) ---');
  print('Precision@1:      ${(overallP1 * 100).toStringAsFixed(1)}%');
  print('Recall@1:         ${(overallR1 * 100).toStringAsFixed(1)}%');
  print('Precision@3:      ${(overallP3 * 100).toStringAsFixed(1)}%');
  print('Recall@3:         ${(overallR3 * 100).toStringAsFixed(1)}%');
  print('Precision@5:      ${(overallP5 * 100).toStringAsFixed(1)}%');
  print('Recall@5:         ${(overallR5 * 100).toStringAsFixed(1)}%');
  print('\n--- RETRIEVAL QUALITY BY CATEGORY ---');
  for (final category in byCategoryResults.keys) {
    final catRes = byCategoryResults[category] as Map<String, dynamic>;
    final cp3 = catRes['precision_at_3'] as double;
    final cr3 = catRes['recall_at_3'] as double;
    final cp5 = catRes['precision_at_5'] as double;
    final cr5 = catRes['recall_at_5'] as double;
    print(
        '${category.padRight(14)} -> Precision@3: ${(cp3 * 100).toStringAsFixed(1)}% | Recall@3: ${(cr3 * 100).toStringAsFixed(1)}%');
    print(
        '${"".padRight(14)}    Precision@5: ${(cp5 * 100).toStringAsFixed(1)}% | Recall@5: ${(cr5 * 100).toStringAsFixed(1)}%');
  }
  print('===============================================================\n');

  // Also write the markdown report for record keeping/backward compatibility
  final report = '''
# Benchmark Report

**Date:** ${DateTime.now().toUtc()}
**Device:** ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)
**Model:** all-MiniLM-L6-v2 (INT8)
**Backend:** ONNX Runtime
**Total Samples:** ${latencies.length}

## Latency (ms)

| Metric | Value |
|--------|-------|
| Avg    | ${toMs(avgLatency).toStringAsFixed(2)} |
| Min    | ${toMs(minLatency).toStringAsFixed(2)} |
| **p50**| **${toMs(p50).toStringAsFixed(2)}** |
| p90    | ${toMs(p90).toStringAsFixed(2)} |
| **p95**| **${toMs(p95).toStringAsFixed(2)}** |
| p99    | ${toMs(p99).toStringAsFixed(2)} |
| Max    | ${toMs(maxLatency).toStringAsFixed(2)} |

## Throughput

- **Est. IPS (Inferences Per Second):** ${(1000000 / avgLatency).toStringAsFixed(1)}

## Retrieval Quality Metrics (Cosine Similarity)

| Category | Precision@1 | Recall@1 | Precision@3 | Recall@3 | Precision@5 | Recall@5 |
|----------|-------------|----------|-------------|----------|-------------|----------|
| **Overall** | ${(overallP1 * 100).toStringAsFixed(1)}% | ${(overallR1 * 100).toStringAsFixed(1)}% | ${(overallP3 * 100).toStringAsFixed(1)}% | ${(overallR3 * 100).toStringAsFixed(1)}% | ${(overallP5 * 100).toStringAsFixed(1)}% | ${(overallR5 * 100).toStringAsFixed(1)}% |
${byCategoryResults.entries.map((e) {
    final cat = e.key;
    final val = e.value as Map<String, dynamic>;
    final p1 = val['precision_at_1'] as double;
    final r1 = val['recall_at_1'] as double;
    final p3 = val['precision_at_3'] as double;
    final r3 = val['recall_at_3'] as double;
    final p5 = val['precision_at_5'] as double;
    final r5 = val['recall_at_5'] as double;
    return '| $cat | ${(p1 * 100).toStringAsFixed(1)}% | ${(r1 * 100).toStringAsFixed(1)}% | ${(p3 * 100).toStringAsFixed(1)}% | ${(r3 * 100).toStringAsFixed(1)}% | ${(p5 * 100).toStringAsFixed(1)}% | ${(r5 * 100).toStringAsFixed(1)}% |';
  }).join('\n')}
''';

  final file = File('BENCHMARK_REPORT.md');
  await file.writeAsString(report);
}
