/// Represents a single embedding inference observation.
class EmbeddingTelemetrySample {
  EmbeddingTelemetrySample({
    required this.runtime,
    required this.modelId,
    required this.latency,
    required this.dimension,
    required this.success,
    this.memoryBytes,
    this.extra,
  });

  final String runtime;
  final String modelId;
  final Duration latency;
  final int dimension;
  final bool success;
  final int? memoryBytes;
  final Map<String, Object?>? extra;
}

/// Maintains rolling statistics for embedding executions.
class EmbeddingTelemetryRecorder {
  EmbeddingTelemetryRecorder({this.maxSamples = 200, this.onSample});

  final int maxSamples;
  final void Function(EmbeddingTelemetrySample sample)? onSample;

  final List<EmbeddingTelemetrySample> _samples = <EmbeddingTelemetrySample>[];

  void record(EmbeddingTelemetrySample sample) {
    if (_samples.length == maxSamples) {
      _samples.removeAt(0);
    }
    _samples.add(sample);
    onSample?.call(sample);
  }

  /// Aggregated metrics for the current sample window.
  Map<String, Object?> snapshot() {
    if (_samples.isEmpty) {
      return <String, Object?>{'count': 0};
    }
    final latencies =
        _samples.map((s) => s.latency.inMicroseconds.toDouble()).toList();
    latencies.sort();
    final total = latencies.reduce((a, b) => a + b);
    final successCount = _samples
        .where((s) => s.success)
        .length
        .toDouble()
        .clamp(0, double.infinity);

    double percentile(double p) {
      if (latencies.isEmpty) return double.nan;
      final rank = (p / 100.0) * (latencies.length - 1);
      final lower = latencies[rank.floor()];
      final upper = latencies[rank.ceil()];
      final fraction = rank - rank.floor();
      return lower + (upper - lower) * fraction;
    }

    int? avgMemoryBytes;
    final memoryValues = _samples
        .where((s) => s.memoryBytes != null)
        .map((s) => s.memoryBytes!)
        .toList();
    if (memoryValues.isNotEmpty) {
      avgMemoryBytes =
          (memoryValues.reduce((a, b) => a + b) / memoryValues.length).round();
    }

    return <String, Object?>{
      'count': _samples.length,
      'latencyAvgMicros': total / latencies.length,
      'latencyP50Micros': percentile(50),
      'latencyP95Micros': percentile(95),
      'successRate': successCount / _samples.length,
      'avgMemoryBytes': avgMemoryBytes,
    };
  }

  /// Clears accumulated samples.
  void reset() => _samples.clear();
}
