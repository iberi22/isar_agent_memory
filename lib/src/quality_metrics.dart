import 'dart:math';
import 'package:isar/isar.dart';
import 'memory_graph.dart';
import 'models/memory_node.dart';

/// Service for measuring and tracking memory quality metrics.
///
/// Provides insights into retrieval quality, coverage, diversity, and latency.
class QualityMetrics {
  final MemoryGraph memoryGraph;
  final List<QueryMetrics> _queryHistory = [];
  final int maxHistorySize;

  QualityMetrics(this.memoryGraph, {this.maxHistorySize = 1000});

  /// Records metrics for a search query.
  ///
  /// Should be called after each search operation.
  void recordQuery({
    required String query,
    required int resultsReturned,
    required double latencyMs,
    int? relevantResults,
    double? averageDistance,
  }) {
    final metrics = QueryMetrics(
      query: query,
      timestamp: DateTime.now(),
      resultsReturned: resultsReturned,
      latencyMs: latencyMs,
      relevantResults: relevantResults,
      averageDistance: averageDistance,
    );

    _queryHistory.add(metrics);

    // Maintain max history size
    if (_queryHistory.length > maxHistorySize) {
      _queryHistory.removeAt(0);
    }
  }

  /// Calculates relevance score for a set of search results.
  ///
  /// Uses distance-based scoring where lower distance = higher relevance.
  double calculateRelevanceScore(List<double> distances) {
    if (distances.isEmpty) return 0.0;

    // Convert distances to relevance scores (1 - distance)
    final relevanceScores = distances.map((d) => 1.0 - d).toList();

    // Use weighted average with exponential decay
    double totalWeight = 0.0;
    double weightedSum = 0.0;

    for (int i = 0; i < relevanceScores.length; i++) {
      final weight = exp(-0.1 * i); // Exponential decay
      weightedSum += relevanceScores[i] * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// Calculates diversity of search results.
  ///
  /// Measures how different the results are from each other.
  /// Returns a value between 0 (identical results) and 1 (very diverse).
  double calculateDiversity(List<int> nodeIds) {
    if (nodeIds.length < 2) return 0.0;

    // This is a placeholder - in practice, you'd compare embeddings
    // For now, we'll use a simple heuristic based on unique types
    return min(1.0, nodeIds.toSet().length / nodeIds.length);
  }

  /// Calculates coverage - what percentage of memory was utilized.
  ///
  /// [accessedNodeIds]: Nodes that were retrieved in searches.
  Future<double> calculateCoverage(Set<int> accessedNodeIds) async {
    final totalNodes = await memoryGraph.isar.memoryNodes.count();
    if (totalNodes == 0) return 0.0;
    return accessedNodeIds.length / totalNodes;
  }

  /// Gets average latency across recent queries.
  double getAverageLatency({int? lastN}) {
    if (_queryHistory.isEmpty) return 0.0;

    final queries = lastN != null
        ? _queryHistory.skip(max(0, _queryHistory.length - lastN))
        : _queryHistory;

    final sum = queries.fold<double>(0.0, (sum, q) => sum + q.latencyMs);
    return sum / queries.length;
  }

  /// Gets percentile latency (e.g., p95, p99).
  double getLatencyPercentile(double percentile) {
    if (_queryHistory.isEmpty) return 0.0;

    final latencies = _queryHistory.map((q) => q.latencyMs).toList()..sort();
    final index = ((percentile / 100) * latencies.length).floor();
    return latencies[min(index, latencies.length - 1)];
  }

  /// Gets average relevance score across recent queries.
  double getAverageRelevance({int? lastN}) {
    final queries = lastN != null
        ? _queryHistory.skip(max(0, _queryHistory.length - lastN))
        : _queryHistory;

    final withRelevance = queries.where((q) => q.averageDistance != null);
    if (withRelevance.isEmpty) return 0.0;

    final sum = withRelevance.fold<double>(
      0.0,
      (sum, q) => sum + (1.0 - q.averageDistance!),
    );
    return sum / withRelevance.length;
  }

  /// Gets comprehensive quality report.
  Future<QualityReport> generateReport({
    Duration? period,
    Set<int>? accessedNodeIds,
  }) async {
    final cutoff = period != null
        ? DateTime.now().subtract(period)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final recentQueries =
        _queryHistory.where((q) => q.timestamp.isAfter(cutoff));

    final totalNodes = await memoryGraph.isar.memoryNodes.count();
    final nodesWithEmbeddings = await memoryGraph.isar.memoryNodes
        .filter()
        .embeddingIsNotNull()
        .count();

    return QualityReport(
      totalQueries: recentQueries.length,
      totalNodes: totalNodes,
      nodesWithEmbeddings: nodesWithEmbeddings,
      averageLatencyMs: getAverageLatency(),
      p95LatencyMs: getLatencyPercentile(95),
      p99LatencyMs: getLatencyPercentile(99),
      averageRelevance: getAverageRelevance(),
      coverage: accessedNodeIds != null
          ? await calculateCoverage(accessedNodeIds)
          : 0.0,
      periodStart: recentQueries.isEmpty
          ? DateTime.now()
          : recentQueries.first.timestamp,
      periodEnd: DateTime.now(),
    );
  }

  /// Clears query history.
  void clearHistory() {
    _queryHistory.clear();
  }

  /// Gets raw query history for analysis.
  List<QueryMetrics> getQueryHistory({int? lastN}) {
    if (lastN != null) {
      return _queryHistory.skip(max(0, _queryHistory.length - lastN)).toList();
    }
    return List.from(_queryHistory);
  }
}

/// Metrics for a single query.
class QueryMetrics {
  final String query;
  final DateTime timestamp;
  final int resultsReturned;
  final double latencyMs;
  final int? relevantResults;
  final double? averageDistance;

  QueryMetrics({
    required this.query,
    required this.timestamp,
    required this.resultsReturned,
    required this.latencyMs,
    this.relevantResults,
    this.averageDistance,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultsReturned': resultsReturned,
      'latencyMs': latencyMs,
      'relevantResults': relevantResults,
      'averageDistance': averageDistance,
    };
  }
}

/// Comprehensive quality report.
class QualityReport {
  final int totalQueries;
  final int totalNodes;
  final int nodesWithEmbeddings;
  final double averageLatencyMs;
  final double p95LatencyMs;
  final double p99LatencyMs;
  final double averageRelevance;
  final double coverage;
  final DateTime periodStart;
  final DateTime periodEnd;

  QualityReport({
    required this.totalQueries,
    required this.totalNodes,
    required this.nodesWithEmbeddings,
    required this.averageLatencyMs,
    required this.p95LatencyMs,
    required this.p99LatencyMs,
    required this.averageRelevance,
    required this.coverage,
    required this.periodStart,
    required this.periodEnd,
  });

  double get embeddingCoverage =>
      totalNodes > 0 ? nodesWithEmbeddings / totalNodes : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalQueries': totalQueries,
      'totalNodes': totalNodes,
      'nodesWithEmbeddings': nodesWithEmbeddings,
      'embeddingCoverage': embeddingCoverage,
      'latency': {
        'average': averageLatencyMs,
        'p95': p95LatencyMs,
        'p99': p99LatencyMs,
      },
      'averageRelevance': averageRelevance,
      'coverage': coverage,
      'period': {
        'start': periodStart.toIso8601String(),
        'end': periodEnd.toIso8601String(),
      },
    };
  }

  @override
  String toString() {
    return '''Quality Report (${periodStart.toIso8601String()} - ${periodEnd.toIso8601String()})
Queries: $totalQueries
Nodes: $totalNodes (${(embeddingCoverage * 100).toStringAsFixed(1)}% with embeddings)
Latency: avg=${averageLatencyMs.toStringAsFixed(1)}ms, p95=${p95LatencyMs.toStringAsFixed(1)}ms, p99=${p99LatencyMs.toStringAsFixed(1)}ms
Relevance: ${(averageRelevance * 100).toStringAsFixed(1)}%
Coverage: ${(coverage * 100).toStringAsFixed(1)}%''';
  }
}
