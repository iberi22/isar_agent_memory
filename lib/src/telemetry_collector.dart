import 'dart:convert';

/// Advanced telemetry collector for performance monitoring
class TelemetryCollector {
  TelemetryCollector({this.enableFileLogging = false});

  final bool enableFileLogging;
  final List<PerformanceEvent> _events = [];

  /// Records a performance event
  void recordEvent(PerformanceEvent event) {
    _events.add(event);
    if (enableFileLogging) {
      _logToFile(event);
    }
  }

  /// Creates a performance report
  PerformanceReport generateReport() {
    final embeddingEvents = _events
        .whereType<EmbeddingPerformanceEvent>()
        .toList();
    final pipelineEvents = _events
        .whereType<PipelinePerformanceEvent>()
        .toList();

    return PerformanceReport(
      totalEvents: _events.length,
      embeddingSummary: _summarizeEmbeddings(embeddingEvents),
      pipelineSummary: _summarizePipelines(pipelineEvents),
      timestamp: DateTime.now().toUtc(),
    );
  }

  EmbeddingSummary _summarizeEmbeddings(
    List<EmbeddingPerformanceEvent> events,
  ) {
    if (events.isEmpty) {
      return EmbeddingSummary(
        totalRequests: 0,
        successRate: 0.0,
        avgLatencyMs: 0.0,
        p95LatencyMs: 0.0,
        providerBreakdown: {},
      );
    }

    final latencies = events.map((e) => e.latencyMs).toList()..sort();
    final successes = events.where((e) => e.success).length;
    final providerCounts = <String, int>{};

    for (final event in events) {
      providerCounts[event.provider] =
          (providerCounts[event.provider] ?? 0) + 1;
    }

    return EmbeddingSummary(
      totalRequests: events.length,
      successRate: successes / events.length,
      avgLatencyMs: latencies.reduce((a, b) => a + b) / latencies.length,
      p95LatencyMs: latencies[(latencies.length * 0.95).floor()],
      providerBreakdown: providerCounts,
    );
  }

  PipelineSummary _summarizePipelines(List<PipelinePerformanceEvent> events) {
    if (events.isEmpty) {
      return PipelineSummary(
        totalRuns: 0,
        successRate: 0.0,
        avgDurationMs: 0.0,
        taskBreakdown: {},
      );
    }

    final runs = events.where((e) => e.stage == 'completed').length;
    final successes = events.where((e) => e.stage == 'completed').length;
    final durations = events
        .where((e) => e.stage == 'completed')
        .map((e) => e.durationMs)
        .toList();

    final taskCounts = <String, int>{};
    for (final event in events) {
      taskCounts[event.taskName] = (taskCounts[event.taskName] ?? 0) + 1;
    }

    return PipelineSummary(
      totalRuns: runs,
      successRate: runs > 0 ? successes / runs : 0.0,
      avgDurationMs: durations.isNotEmpty
          ? durations.reduce((a, b) => a + b) / durations.length
          : 0.0,
      taskBreakdown: taskCounts,
    );
  }

  void _logToFile(PerformanceEvent event) {
    // TODO: Implement file logging
  }

  /// Clears collected events
  void clear() {
    _events.clear();
  }

  /// Export events as JSON
  String exportAsJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'events': _events.map((e) => e.toJson()).toList(),
    });
  }
}

/// Base class for performance events
abstract class PerformanceEvent {
  PerformanceEvent({required this.timestamp});

  final DateTime timestamp;

  Map<String, Object?> toJson();
}

/// Performance event for embedding operations
class EmbeddingPerformanceEvent extends PerformanceEvent {
  EmbeddingPerformanceEvent({
    required this.provider,
    required this.modelId,
    required this.latencyMs,
    required this.dimension,
    required this.success,
    this.error,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now().toUtc());

  final String provider;
  final String modelId;
  final double latencyMs;
  final int dimension;
  final bool success;
  final String? error;

  @override
  Map<String, Object?> toJson() => {
    'type': 'embedding',
    'timestamp': timestamp.toIso8601String(),
    'provider': provider,
    'model_id': modelId,
    'latency_ms': latencyMs,
    'dimension': dimension,
    'success': success,
    if (error != null) 'error': error,
  };
}

/// Performance event for pipeline operations
class PipelinePerformanceEvent extends PerformanceEvent {
  PipelinePerformanceEvent({
    required this.taskName,
    required this.stage,
    required this.durationMs,
    this.metadata = const {},
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now().toUtc());

  final String taskName;
  final String stage;
  final double durationMs;
  final Map<String, Object?> metadata;

  @override
  Map<String, Object?> toJson() => {
    'type': 'pipeline',
    'timestamp': timestamp.toIso8601String(),
    'task_name': taskName,
    'stage': stage,
    'duration_ms': durationMs,
    'metadata': metadata,
  };
}

/// Summary of embedding performance
class EmbeddingSummary {
  EmbeddingSummary({
    required this.totalRequests,
    required this.successRate,
    required this.avgLatencyMs,
    required this.p95LatencyMs,
    required this.providerBreakdown,
  });

  final int totalRequests;
  final double successRate;
  final double avgLatencyMs;
  final double p95LatencyMs;
  final Map<String, int> providerBreakdown;
}

/// Summary of pipeline performance
class PipelineSummary {
  PipelineSummary({
    required this.totalRuns,
    required this.successRate,
    required this.avgDurationMs,
    required this.taskBreakdown,
  });

  final int totalRuns;
  final double successRate;
  final double avgDurationMs;
  final Map<String, int> taskBreakdown;
}

/// Complete performance report
class PerformanceReport {
  PerformanceReport({
    required this.totalEvents,
    required this.embeddingSummary,
    required this.pipelineSummary,
    required this.timestamp,
  });

  final int totalEvents;
  final EmbeddingSummary embeddingSummary;
  final PipelineSummary pipelineSummary;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'total_events': totalEvents,
    'embedding_summary': {
      'total_requests': embeddingSummary.totalRequests,
      'success_rate': embeddingSummary.successRate,
      'avg_latency_ms': embeddingSummary.avgLatencyMs,
      'p95_latency_ms': embeddingSummary.p95LatencyMs,
      'provider_breakdown': embeddingSummary.providerBreakdown,
    },
    'pipeline_summary': {
      'total_runs': pipelineSummary.totalRuns,
      'success_rate': pipelineSummary.successRate,
      'avg_duration_ms': pipelineSummary.avgDurationMs,
      'task_breakdown': pipelineSummary.taskBreakdown,
    },
  };

  void printSummary() {
    print('🔍 PERFORMANCE REPORT');
    print('=' * 40);
    print('Generated: ${timestamp.toLocal()}');
    print('Total Events: $totalEvents');
    print('');

    print('📊 Embedding Summary:');
    print('  Requests: ${embeddingSummary.totalRequests}');
    print(
      '  Success Rate: ${(embeddingSummary.successRate * 100).toStringAsFixed(1)}%',
    );
    print(
      '  Avg Latency: ${embeddingSummary.avgLatencyMs.toStringAsFixed(1)}ms',
    );
    print(
      '  P95 Latency: ${embeddingSummary.p95LatencyMs.toStringAsFixed(1)}ms',
    );
    print('  Providers: ${embeddingSummary.providerBreakdown}');
    print('');

    print('⚡ Pipeline Summary:');
    print('  Runs: ${pipelineSummary.totalRuns}');
    print(
      '  Success Rate: ${(pipelineSummary.successRate * 100).toStringAsFixed(1)}%',
    );
    print(
      '  Avg Duration: ${pipelineSummary.avgDurationMs.toStringAsFixed(1)}ms',
    );
    print('  Tasks: ${pipelineSummary.taskBreakdown}');
  }
}
