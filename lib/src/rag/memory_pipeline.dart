import '../models/memory_node.dart';

/// Base class for a pipeline stage.
abstract class PipelineStage<I, O> {
  Future<O> process(I input);
}

/// A generic pipeline that executes a series of stages.
abstract class MemoryPipeline<I, O> {
  Future<O> execute(I input);
}

/// Data structure for RAG context and results.
class RagContext {
  final String originalQuery;
  String currentQuery;
  List<String> decomposedQueries;
  List<({MemoryNode node, double score})> retrievedNodes;
  String? generatedResponse;
  List<MemoryNode> citedNodes;

  RagContext({
    required this.originalQuery,
    this.currentQuery = '',
    this.decomposedQueries = const [],
    this.retrievedNodes = const [],
    this.citedNodes = const [],
  }) {
    currentQuery = originalQuery;
  }
}
