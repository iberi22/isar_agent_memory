import 'dart:io';
import 'package:isar_agent_memory/src/on_device_embeddings_adapter.dart';

Future<void> main() async {
  print('Starting Benchmark...');

  // 1. Setup
  final modelPath = 'test_resources/model.onnx';
  final vocabPath = 'test_resources/vocab.txt';

  if (!File(modelPath).existsSync() || !File(vocabPath).existsSync()) {
    print(
        'Error: Model files not found. Run tool/setup_on_device_test.dart first.');
    exit(1);
  }

  final adapter = OnDeviceEmbeddingsAdapter(
    modelPath: modelPath,
    vocabPath: vocabPath,
  );

  await adapter.initialize();

  // Warmup
  print('Warming up...');
  for (var i = 0; i < 5; i++) {
    await adapter.embed('Warmup sentence number $i');
  }

  // 2. Run Benchmark
  final sentences = [
    'The quick brown fox jumps over the lazy dog.',
    'Artificial intelligence is transforming the world.',
    'Flutter is an open source framework by Google for building beautiful, natively compiled, multi-platform applications from a single codebase.',
    'Isar is a super fast cross-platform database for Flutter.',
    'Embeddings are vector representations of text.',
    'Consistency is key to performance.',
    'Benchmark run at ${DateTime.now()}',
    'Short.',
    'A significantly longer sentence to test the impact of tokenization and inference time on larger inputs, although BERT models usually handle up to 512 tokens comfortably.',
    'Mobile development requires efficient resource usage.'
  ];

  final latencies = <int>[];
  final iterations = 50;

  print('Running $iterations iterations over ${sentences.length} sentences...');

  final stopwatch = Stopwatch();

  for (var i = 0; i < iterations; i++) {
    for (final sentence in sentences) {
      stopwatch.reset();
      stopwatch.start();
      await adapter.embed(sentence);
      stopwatch.stop();
      latencies.add(stopwatch.elapsedMicroseconds);
    }
  }

  adapter.release();

  // 3. Analyze
  latencies.sort();
  final avg = latencies.reduce((a, b) => a + b) / latencies.length;
  final p50 = latencies[(latencies.length * 0.50).floor()];
  final p90 = latencies[(latencies.length * 0.90).floor()];
  final p95 = latencies[(latencies.length * 0.95).floor()];
  final p99 = latencies[(latencies.length * 0.99).floor()];
  final min = latencies.first;
  final max = latencies.last;

  // Convert to ms
  double toMs(num micro) => micro / 1000.0;

  final report = '''
# Benchmark Report

**Date:** ${DateTime.now().toUtc()}
**Device:** ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)
**Model:** all-MiniLM-L6-v2 (INT8)
**Backend:** ONNX Runtime
**Samples:** ${latencies.length}

## Latency (ms)

| Metric | Value |
|--------|-------|
| Avg    | ${toMs(avg).toStringAsFixed(2)} |
| Min    | ${toMs(min).toStringAsFixed(2)} |
| **p50**| **${toMs(p50).toStringAsFixed(2)}** |
| p90    | ${toMs(p90).toStringAsFixed(2)} |
| **p95**| **${toMs(p95).toStringAsFixed(2)}** |
| p99    | ${toMs(p99).toStringAsFixed(2)} |
| Max    | ${toMs(max).toStringAsFixed(2)} |

## Throughput

- **Total Time:** ${(toMs(latencies.reduce((a, b) => a + b)) / 1000).toStringAsFixed(2)} s
- **Est. IPS (Inferences Per Second):** ${(1000000 / avg).toStringAsFixed(1)}

''';

  print(report);

  // Write to file
  final file = File('BENCHMARK_REPORT.md');
  await file.writeAsString(report);
  print('Report saved to BENCHMARK_REPORT.md');
}
